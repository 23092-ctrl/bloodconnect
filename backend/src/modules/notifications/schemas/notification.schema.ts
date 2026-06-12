import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { BloodType } from '../../../common/enums/blood-type.enum';

export type NotificationDocument = Notification & Document;

export enum NotificationType {
  SHORTAGE_ALERT = 'shortage_alert',
  REMINDER = 'reminder',
  CAMPAIGN = 'campaign',
  GENERAL = 'general',
}

@Schema({ timestamps: true })
export class Notification {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  @Prop({ required: true })
  title: string;

  @Prop({ required: true })
  body: string;

  @Prop({ required: true, enum: NotificationType, default: NotificationType.GENERAL })
  type: NotificationType;

  @Prop({ enum: BloodType })
  bloodType: BloodType;

  @Prop({ type: Types.ObjectId, ref: 'BloodCenter' })
  centerId: Types.ObjectId;

  @Prop({ default: false })
  isRead: boolean;

  @Prop({ default: false })
  isSent: boolean;

  @Prop()
  sentAt: Date;
}

export const NotificationSchema = SchemaFactory.createForClass(Notification);

NotificationSchema.index({ userId: 1, isRead: 1 });
