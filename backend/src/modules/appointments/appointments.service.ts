import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  Appointment,
  AppointmentDocument,
  AppointmentStatus,
} from './schemas/appointment.schema';
import { CreateAppointmentDto } from './dto/create-appointment.dto';
import { DonationsService } from '../donations/donations.service';
import { UsersService } from '../users/users.service';
import { BloodType } from '../../common/enums/blood-type.enum';

@Injectable()
export class AppointmentsService {
  constructor(
    @InjectModel(Appointment.name)
    private appointmentModel: Model<AppointmentDocument>,
    private donationsService: DonationsService,
    private usersService: UsersService,
  ) {}

  async create(donorId: string, dto: CreateAppointmentDto): Promise<AppointmentDocument> {
    const donor = await this.usersService.findById(donorId);

    if (!donor.medicallyEligible) {
      throw new BadRequestException(
        'You are not medically eligible to donate at this time. Please contact your center for more information.',
      );
    }

    if (donor.lastDonationDate) {
      const daysSince = Math.floor(
        (Date.now() - new Date(donor.lastDonationDate).getTime()) / (1000 * 60 * 60 * 24),
      );
      if (daysSince < 56) {
        const daysLeft = 56 - daysSince;
        throw new BadRequestException(
          `You must wait ${daysLeft} more day${daysLeft > 1 ? 's' : ''} before donating again (56-day interval required).`,
        );
      }
    }

    if (donor.bloodType && donor.bloodType !== dto.bloodType) {
      throw new BadRequestException(
        `Your registered blood type is ${donor.bloodType}. You can only donate your own blood type.`,
      );
    }

    const existing = await this.appointmentModel.findOne({
      donorId,
      centerId: dto.centerId,
      bloodType: dto.bloodType,
      status: { $in: [AppointmentStatus.PENDING, AppointmentStatus.CONFIRMED] },
    });
    if (existing) throw new BadRequestException('You already have a pending request for this blood type at this center');

    return new this.appointmentModel({
      donorId,
      centerId: dto.centerId,
      bloodType: dto.bloodType,
      scheduledDate: dto.scheduledDate ? new Date(dto.scheduledDate) : null,
      notes: dto.notes,
    }).save();
  }

  async confirm(id: string): Promise<AppointmentDocument> {
    const appt = await this.appointmentModel.findById(id);
    if (!appt) throw new NotFoundException('Request not found');
    if (appt.status !== AppointmentStatus.PENDING)
      throw new BadRequestException('Only pending requests can be confirmed');
    appt.status = AppointmentStatus.CONFIRMED;
    return appt.save();
  }

  async complete(id: string): Promise<AppointmentDocument> {
    const appt = await this.appointmentModel.findById(id);
    if (!appt) throw new NotFoundException('Request not found');
    if (appt.status !== AppointmentStatus.CONFIRMED)
      throw new BadRequestException('Only confirmed requests can be completed');

    await this.donationsService.create(appt.donorId.toString(), {
      centerId: appt.centerId.toString(),
      bloodType: appt.bloodType,
      units: 1,
    } as any);

    appt.status = AppointmentStatus.COMPLETED;
    return appt.save();
  }

  async reject(id: string, reason?: string): Promise<AppointmentDocument> {
    const appt = await this.appointmentModel.findById(id);
    if (!appt) throw new NotFoundException('Request not found');
    if (![AppointmentStatus.PENDING, AppointmentStatus.CONFIRMED].includes(appt.status))
      throw new BadRequestException('Cannot reject this request');
    appt.status = AppointmentStatus.REJECTED;
    if (reason) appt.rejectionReason = reason;
    return appt.save();
  }

  async cancel(id: string, donorId: string): Promise<void> {
    const appt = await this.appointmentModel.findOne({ _id: id, donorId });
    if (!appt) throw new NotFoundException('Request not found');
    if (![AppointmentStatus.PENDING, AppointmentStatus.CONFIRMED].includes(appt.status))
      throw new ForbiddenException('Cannot cancel this request');
    appt.status = AppointmentStatus.CANCELLED;
    await appt.save();
  }

  async findByDonor(donorId: string) {
    return this.appointmentModel
      .find({ donorId })
      .populate('centerId', 'name address phone')
      .sort({ createdAt: -1 })
      .lean();
  }

  async findByCenter(centerId: string, status?: string) {
    const query: any = { centerId };
    if (status) query.status = status;
    return this.appointmentModel
      .find(query)
      .populate('donorId', 'fullName bloodType phone email')
      .sort({ createdAt: -1 })
      .lean();
  }

  async autoConfirmForBloodType(bloodType: BloodType, centerId: string): Promise<number> {
    const result = await this.appointmentModel.updateMany(
      { bloodType, centerId, status: AppointmentStatus.PENDING },
      { status: AppointmentStatus.CONFIRMED, autoConfirmed: true },
    );
    return result.modifiedCount;
  }
}
