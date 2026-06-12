import { Module } from '@nestjs/common';
import { ShortageEngineService } from './shortage-engine.service';
import { BloodInventoryModule } from '../blood-inventory/blood-inventory.module';
import { UsersModule } from '../users/users.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { BloodCentersModule } from '../blood-centers/blood-centers.module';
import { AppointmentsModule } from '../appointments/appointments.module';

@Module({
  imports: [BloodInventoryModule, UsersModule, NotificationsModule, BloodCentersModule, AppointmentsModule],
  providers: [ShortageEngineService],
  exports: [ShortageEngineService],
})
export class ShortageEngineModule {}
