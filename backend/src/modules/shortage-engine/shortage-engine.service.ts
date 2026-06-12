import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { BloodInventoryService } from '../blood-inventory/blood-inventory.service';
import { UsersService } from '../users/users.service';
import { NotificationsService } from '../notifications/notifications.service';
import { BloodCentersService } from '../blood-centers/blood-centers.service';
import { AppointmentsService } from '../appointments/appointments.service';
import { StockStatus } from '../blood-inventory/schemas/blood-inventory.schema';

@Injectable()
export class ShortageEngineService {
  private readonly logger = new Logger(ShortageEngineService.name);

  constructor(
    private inventoryService: BloodInventoryService,
    private usersService: UsersService,
    private notificationsService: NotificationsService,
    private centersService: BloodCentersService,
    private appointmentsService: AppointmentsService,
  ) {}

  @Cron(CronExpression.EVERY_30_MINUTES)
  async runShortageDetection(): Promise<void> {
    this.logger.log('Running shortage detection cycle...');

    try {
      const shortages = await this.inventoryService.detectShortages();

      if (!shortages.length) {
        this.logger.log('No shortages detected.');
        return;
      }

      this.logger.log(`Detected ${shortages.length} shortage(s).`);

      for (const shortage of shortages) {
        if (shortage.status === StockStatus.CRITICAL) {
          await this.handleCriticalShortage(shortage);
        }
      }
    } catch (err) {
      this.logger.error('Shortage detection failed', err);
    }
  }

  private async handleCriticalShortage(shortage: any): Promise<void> {
    this.logger.warn(
      `CRITICAL shortage: ${shortage.bloodType} — ${shortage.totalUnits} units remaining`,
    );

    const [donors, centerIds] = await Promise.all([
      this.usersService.findEligibleDonors(shortage.bloodType),
      Promise.resolve(shortage.centers.map((c) => c.centerId?.toString()).filter(Boolean)),
    ]);

    if (!donors.length) {
      this.logger.warn(`No eligible donors found for ${shortage.bloodType}`);
      return;
    }

    let primaryCenterName = 'your nearest donation center';

    if (centerIds.length) {
      try {
        const center = await this.centersService.findById(centerIds[0]);
        if (center) primaryCenterName = center.name;
      } catch {
        // center lookup failed, use fallback name
      }
    }

    this.logger.log(
      `Notifying ${donors.length} eligible donors for ${shortage.bloodType}...`,
    );

    await this.notificationsService.sendShortageAlert(
      donors,
      shortage.bloodType,
      primaryCenterName,
    );

    this.logger.log(`Shortage alert sent for ${shortage.bloodType}`);

    // Auto-confirm all pending appointments for this blood type across affected centers
    let totalAutoConfirmed = 0;
    for (const centerId of centerIds) {
      const count = await this.appointmentsService.autoConfirmForBloodType(
        shortage.bloodType,
        centerId,
      );
      totalAutoConfirmed += count;
    }
    if (totalAutoConfirmed > 0) {
      this.logger.log(
        `Auto-confirmed ${totalAutoConfirmed} pending request(s) for ${shortage.bloodType}`,
      );
    }
  }

  async triggerManually(): Promise<{ shortagesFound: number; donorsNotified: number }> {
    const shortages = await this.inventoryService.detectShortages();
    let donorsNotified = 0;

    for (const shortage of shortages) {
      if (shortage.status === StockStatus.CRITICAL) {
        const donors = await this.usersService.findEligibleDonors(shortage.bloodType);
        donorsNotified += donors.length;
        await this.handleCriticalShortage(shortage);
      }
    }

    return { shortagesFound: shortages.length, donorsNotified };
  }
}
