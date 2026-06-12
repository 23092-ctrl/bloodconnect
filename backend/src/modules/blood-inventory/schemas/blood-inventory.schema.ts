import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { BloodType } from '../../../common/enums/blood-type.enum';

export type BloodInventoryDocument = BloodInventory & Document;

export enum StockStatus {
  NORMAL = 'normal',
  LOW = 'low',
  CRITICAL = 'critical',
}

@Schema({ timestamps: true })
export class BloodInventory {
  @Prop({ type: Types.ObjectId, ref: 'BloodCenter', required: true })
  centerId: Types.ObjectId;

  @Prop({ required: true, enum: BloodType })
  bloodType: BloodType;

  @Prop({ required: true, min: 0, default: 0 })
  availableUnits: number;

  @Prop({ required: true, default: 20 })
  safeThreshold: number;

  @Prop({ required: true, default: 10 })
  criticalThreshold: number;

  @Prop({ default: Date.now })
  lastUpdated: Date;
}

export const BloodInventorySchema = SchemaFactory.createForClass(BloodInventory);

BloodInventorySchema.index({ centerId: 1, bloodType: 1 }, { unique: true });

BloodInventorySchema.virtual('status').get(function () {
  if (this.availableUnits <= this.criticalThreshold) return StockStatus.CRITICAL;
  if (this.availableUnits <= this.safeThreshold) return StockStatus.LOW;
  return StockStatus.NORMAL;
});

BloodInventorySchema.set('toJSON', { virtuals: true });
BloodInventorySchema.set('toObject', { virtuals: true });
