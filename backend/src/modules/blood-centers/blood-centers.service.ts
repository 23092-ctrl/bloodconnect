import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { BloodCenter, BloodCenterDocument } from './schemas/blood-center.schema';
import { CreateBloodCenterDto } from './dto/create-blood-center.dto';

@Injectable()
export class BloodCentersService {
  constructor(
    @InjectModel(BloodCenter.name)
    private centerModel: Model<BloodCenterDocument>,
  ) {}

  async create(dto: CreateBloodCenterDto): Promise<BloodCenterDocument> {
    return new this.centerModel(dto).save();
  }

  async findAll(page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [centers, total] = await Promise.all([
      this.centerModel.find({ isActive: true }).skip(skip).limit(limit).lean(),
      this.centerModel.countDocuments({ isActive: true }),
    ]);
    return { centers, total, page, limit };
  }

  async findById(id: string): Promise<BloodCenterDocument> {
    const center = await this.centerModel.findById(id);
    if (!center) throw new NotFoundException('Blood center not found');
    return center;
  }

  async findNearest(
    lng: number,
    lat: number,
    maxDistanceKm = 50,
  ): Promise<BloodCenterDocument[]> {
    return this.centerModel.find({
      isActive: true,
      location: {
        $near: {
          $geometry: { type: 'Point', coordinates: [lng, lat] },
          $maxDistance: maxDistanceKm * 1000,
        },
      },
    });
  }

  async verify(id: string): Promise<BloodCenterDocument> {
    const center = await this.centerModel.findByIdAndUpdate(
      id,
      { isVerified: true },
      { new: true },
    );
    if (!center) throw new NotFoundException('Blood center not found');
    return center;
  }

  async update(id: string, dto: Partial<CreateBloodCenterDto>) {
    const center = await this.centerModel.findByIdAndUpdate(id, dto, { new: true });
    if (!center) throw new NotFoundException('Blood center not found');
    return center;
  }
}
