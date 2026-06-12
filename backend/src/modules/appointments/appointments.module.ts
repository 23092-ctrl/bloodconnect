import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Appointment, AppointmentSchema } from './schemas/appointment.schema';
import { AppointmentsService } from './appointments.service';
import { AppointmentsController } from './appointments.controller';
import { DonationsModule } from '../donations/donations.module';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Appointment.name, schema: AppointmentSchema },
    ]),
    DonationsModule,
    UsersModule,
  ],
  controllers: [AppointmentsController],
  providers: [AppointmentsService],
  exports: [AppointmentsService],
})
export class AppointmentsModule {}
