import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  BloodInventory,
  BloodInventoryDocument,
  StockStatus,
} from './schemas/blood-inventory.schema';
import { UpdateInventoryDto } from './dto/update-inventory.dto';
import { BloodType } from '../../common/enums/blood-type.enum';

export interface ShortageEntry {
  bloodType: BloodType;
  totalUnits: number;
  status: StockStatus;
  centers: any[];
}

@Injectable()
export class BloodInventoryService {
  constructor(
    @InjectModel(BloodInventory.name)
    private inventoryModel: Model<BloodInventoryDocument>,
  ) {}

  async incrementUnits(centerId: string, bloodType: BloodType, units: number): Promise<void> {
    await this.inventoryModel.findOneAndUpdate(
      { centerId, bloodType },
      { $inc: { availableUnits: units }, lastUpdated: new Date() },
      { upsert: true, new: true },
    );
  }

  async upsert(centerId: string, dto: UpdateInventoryDto): Promise<BloodInventoryDocument> {
    const inventory = await this.inventoryModel.findOneAndUpdate(
      { centerId, bloodType: dto.bloodType },
      {
        availableUnits: dto.availableUnits,
        ...(dto.safeThreshold && { safeThreshold: dto.safeThreshold }),
        ...(dto.criticalThreshold && { criticalThreshold: dto.criticalThreshold }),
        lastUpdated: new Date(),
      },
      { upsert: true, new: true },
    );
    return inventory;
  }

  async findByCenterId(centerId: string): Promise<any[]> {
    return this.inventoryModel.find({ centerId }).lean();
  }

  async getGlobalSummary(): Promise<Record<BloodType, { totalUnits: number; status: string }>> {
    const records = await this.inventoryModel.aggregate([
      {
        $group: {
          _id: '$bloodType',
          totalUnits: { $sum: '$availableUnits' },
          avgSafeThreshold: { $avg: '$safeThreshold' },
          avgCriticalThreshold: { $avg: '$criticalThreshold' },
        },
      },
    ]);

    const summary: any = {};
    for (const r of records) {
      let status = StockStatus.NORMAL;
      if (r.totalUnits <= r.avgCriticalThreshold) status = StockStatus.CRITICAL;
      else if (r.totalUnits <= r.avgSafeThreshold) status = StockStatus.LOW;
      summary[r._id] = { totalUnits: r.totalUnits, status };
    }
    return summary;
  }

  async detectShortages(): Promise<ShortageEntry[]> {
    const records = await this.inventoryModel.find().lean();

    const grouped = new Map<BloodType, any[]>();
    for (const r of records) {
      const list = grouped.get(r.bloodType) || [];
      list.push(r);
      grouped.set(r.bloodType, list);
    }

    const shortages: ShortageEntry[] = [];

    for (const [bloodType, entries] of grouped) {
      const totalUnits = entries.reduce((sum, e) => sum + e.availableUnits, 0);
      const avgCritical = entries.reduce((sum, e) => sum + e.criticalThreshold, 0) / entries.length;
      const avgSafe = entries.reduce((sum, e) => sum + e.safeThreshold, 0) / entries.length;

      let status = StockStatus.NORMAL;
      if (totalUnits <= avgCritical) status = StockStatus.CRITICAL;
      else if (totalUnits <= avgSafe) status = StockStatus.LOW;

      if (status !== StockStatus.NORMAL) {
        shortages.push({ bloodType, totalUnits, status, centers: entries });
      }
    }

    return shortages.sort((a, b) => a.totalUnits - b.totalUnits);
  }
}
