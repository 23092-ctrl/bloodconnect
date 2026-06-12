import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { BloodType } from '../../../common/enums/blood-type.enum';

export type AppointmentDocument = Appointment & Document;

export enum AppointmentStatus {
  PENDING    = 'pending',    // donor submitted, waiting for center
  CONFIRMED  = 'confirmed',  // center accepted
  COMPLETED  = 'completed',  // donor came, donation done → stock updated
  REJECTED   = 'rejected',   // center rejected
  CANCELLED  = 'cancelled',  // donor cancelled
}

@Schema({ timestamps: true })
export class Appointment {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  donorId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'BloodCenter', required: true })
  centerId: Types.ObjectId;

  @Prop({ required: true, enum: BloodType })
  bloodType: BloodType;

  @Prop()
  scheduledDate: Date;

  @Prop({ default: AppointmentStatus.PENDING, enum: AppointmentStatus })
  status: AppointmentStatus;

  @Prop()
  notes: string;

  @Prop()
  rejectionReason: string;

  @Prop({ default: false })
  autoConfirmed: boolean;
}

export const AppointmentSchema = SchemaFactory.createForClass(Appointment);

AppointmentSchema.index({ donorId: 1 });
AppointmentSchema.index({ centerId: 1, status: 1 });
AppointmentSchema.index({ bloodType: 1, status: 1 });
