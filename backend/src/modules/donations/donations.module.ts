import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Donation, DonationSchema } from './schemas/donation.schema';
import { DonationsService } from './donations.service';
import { DonationsController } from './donations.controller';
import { UsersModule } from '../users/users.module';
import { BloodInventoryModule } from '../blood-inventory/blood-inventory.module';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Donation.name, schema: DonationSchema }]),
    UsersModule,
    BloodInventoryModule,
  ],
  controllers: [DonationsController],
  providers: [DonationsService],
  exports: [DonationsService],
})
export class DonationsModule {}
