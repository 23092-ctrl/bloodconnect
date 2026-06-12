import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Schema as MongooseSchema } from 'mongoose';
import { BloodType } from '../../../common/enums/blood-type.enum';
import { Role } from '../../../common/enums/role.enum';

export type UserDocument = User & Document;

@Schema({ timestamps: true })
export class User {
  @Prop({ required: true, trim: true })
  fullName: string;

  @Prop({ required: true, unique: true, lowercase: true, trim: true })
  email: string;

  @Prop({ required: true, select: false })
  password: string;

  @Prop({ enum: BloodType })
  bloodType: BloodType;

  @Prop({ enum: ['male', 'female'] })
  gender: string;

  @Prop()
  birthDate: Date;

  @Prop({ trim: true })
  phone: string;

  @Prop({ trim: true })
  address: string;

  @Prop({ type: MongooseSchema.Types.Mixed })
  location?: { type: string; coordinates: number[] };

  @Prop({ default: Role.DONOR, enum: Role })
  role: Role;

  @Prop({ default: true })
  isActive: boolean;

  @Prop({ default: true })
  notificationsEnabled: boolean;

  @Prop({ default: true })
  medicallyEligible: boolean;

  @Prop()
  lastDonationDate: Date;

  @Prop()
  fcmToken: string;

  @Prop()
  profilePicture: string;

  @Prop({ default: false })
  emailVerified: boolean;

  @Prop()
  emailVerificationToken: string;

  @Prop()
  passwordResetToken: string;

  @Prop()
  passwordResetExpires: Date;
}

export const UserSchema = SchemaFactory.createForClass(User);

UserSchema.index({ location: '2dsphere' }, { sparse: true });
