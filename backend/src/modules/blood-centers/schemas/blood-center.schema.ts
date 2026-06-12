import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type BloodCenterDocument = BloodCenter & Document;

@Schema({ timestamps: true })
export class BloodCenter {
  @Prop({ required: true, trim: true })
  name: string;

  @Prop({ required: true })
  address: string;

  @Prop({
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point',
    },
    coordinates: { type: [Number], required: true },
  })
  location: { type: string; coordinates: number[] };

  @Prop({ trim: true })
  phone: string;

  @Prop({ lowercase: true, trim: true })
  email: string;

  @Prop({ default: false })
  isVerified: boolean;

  @Prop({ default: true })
  isActive: boolean;

  @Prop()
  description: string;

  @Prop()
  openingHours: string;
}

export const BloodCenterSchema = SchemaFactory.createForClass(BloodCenter);

BloodCenterSchema.index({ location: '2dsphere' });
