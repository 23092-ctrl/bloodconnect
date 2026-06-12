import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { BloodType } from '../../../common/enums/blood-type.enum';

export type DonationDocument = Donation & Document;

export enum DonationStatus {
  PENDING = 'pending',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled',
}

@Schema({ timestamps: true })
export class Donation {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  donorId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'BloodCenter', required: true })
  centerId: Types.ObjectId;

  @Prop({ required: true, enum: BloodType })
  bloodType: BloodType;

  @Prop({ required: true, default: Date.now })
  donationDate: Date;

  @Prop({ default: 1, min: 1 })
  units: number;

  @Prop({ default: DonationStatus.COMPLETED, enum: DonationStatus })
  status: DonationStatus;

  @Prop()
  notes: string;
}

export const DonationSchema = SchemaFactory.createForClass(Donation);

DonationSchema.index({ donorId: 1 });
DonationSchema.index({ centerId: 1 });
