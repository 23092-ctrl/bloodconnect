import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as bcrypt from 'bcryptjs';
import { User, UserDocument } from './schemas/user.schema';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { BloodType } from '../../common/enums/blood-type.enum';

@Injectable()
export class UsersService {
  constructor(@InjectModel(User.name) private userModel: Model<UserDocument>) {}

  async create(dto: CreateUserDto): Promise<UserDocument> {
    const existing = await this.userModel.findOne({ email: dto.email });
    if (existing) throw new ConflictException('Email already registered');

    const hashed = await bcrypt.hash(dto.password, 12);
    const user = new this.userModel({ ...dto, password: hashed });
    return user.save();
  }

  async findById(id: string): Promise<UserDocument> {
    const user = await this.userModel.findById(id);
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async findByEmail(email: string, withPassword = false): Promise<UserDocument> {
    const query = this.userModel.findOne({ email });
    if (withPassword) query.select('+password');
    return query.exec();
  }

  async update(id: string, dto: UpdateUserDto): Promise<UserDocument> {
    const user = await this.userModel.findByIdAndUpdate(id, dto, { new: true });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async updateFcmToken(id: string, fcmToken: string): Promise<void> {
    await this.userModel.findByIdAndUpdate(id, { fcmToken });
  }

  async findEligibleDonors(bloodType: BloodType): Promise<UserDocument[]> {
    const minDonationInterval = new Date();
    minDonationInterval.setDate(minDonationInterval.getDate() - 56); // 8 weeks

    return this.userModel.find({
      bloodType,
      isActive: true,
      notificationsEnabled: true,
      medicallyEligible: true,
      fcmToken: { $exists: true, $ne: null },
      $or: [
        { lastDonationDate: { $exists: false } },
        { lastDonationDate: { $lte: minDonationInterval } },
      ],
    });
  }

  async findAll(page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [users, total] = await Promise.all([
      this.userModel.find().skip(skip).limit(limit).lean(),
      this.userModel.countDocuments(),
    ]);
    return { users, total, page, limit };
  }

  async deactivate(id: string): Promise<void> {
    await this.userModel.findByIdAndUpdate(id, { isActive: false });
  }
}
