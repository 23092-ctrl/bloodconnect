import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Donation, DonationDocument } from './schemas/donation.schema';
import { CreateDonationDto } from './dto/create-donation.dto';
import { UsersService } from '../users/users.service';
import { BloodInventoryService } from '../blood-inventory/blood-inventory.service';

@Injectable()
export class DonationsService {
  constructor(
    @InjectModel(Donation.name) private donationModel: Model<DonationDocument>,
    private usersService: UsersService,
    private inventoryService: BloodInventoryService,
  ) {}

  async createWithLookup(callerId: string, dto: CreateDonationDto): Promise<DonationDocument> {
    let donorId = callerId;

    if (dto.donorEmail) {
      const donor = await this.usersService.findByEmail(dto.donorEmail);
      if (!donor) throw new BadRequestException(`No user found with email: ${dto.donorEmail}`);
      donorId = (donor._id as any).toString();
    } else if (dto.donorId) {
      donorId = dto.donorId;
    }

    return this.create(donorId, dto);
  }

  async create(donorId: string, dto: CreateDonationDto): Promise<DonationDocument> {
    const units = dto.units ?? 1;

    const donation = await new this.donationModel({
      donorId,
      ...dto,
      units,
      donationDate: new Date(),
    }).save();

    await Promise.all([
      // mise à jour de la date du dernier don du donateur
      this.usersService.update(donorId, { lastDonationDate: new Date() } as any),
      // incrémentation du stock du centre
      this.inventoryService.incrementUnits(dto.centerId, dto.bloodType, units),
    ]);

    return donation.populate(['donorId', 'centerId']);
  }

  async findByDonor(donorId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [donations, total] = await Promise.all([
      this.donationModel
        .find({ donorId })
        .populate('centerId', 'name address')
        .sort({ donationDate: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      this.donationModel.countDocuments({ donorId }),
    ]);
    return { donations, total, page, limit };
  }

  async findByCenter(centerId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [donations, total] = await Promise.all([
      this.donationModel
        .find({ centerId })
        .populate('donorId', 'fullName bloodType')
        .sort({ donationDate: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      this.donationModel.countDocuments({ centerId }),
    ]);
    return { donations, total, page, limit };
  }

  async getDonorStats(donorId: string) {
    const [total, lastDonation] = await Promise.all([
      this.donationModel.countDocuments({ donorId }),
      this.donationModel
        .findOne({ donorId })
        .sort({ donationDate: -1 })
        .populate('centerId', 'name'),
    ]);
    return { totalDonations: total, lastDonation };
  }
}
