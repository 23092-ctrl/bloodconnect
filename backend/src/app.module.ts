import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { ScheduleModule } from '@nestjs/schedule';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { BloodCentersModule } from './modules/blood-centers/blood-centers.module';
import { BloodInventoryModule } from './modules/blood-inventory/blood-inventory.module';
import { DonationsModule } from './modules/donations/donations.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { AppointmentsModule } from './modules/appointments/appointments.module';
import { ShortageEngineModule } from './modules/shortage-engine/shortage-engine.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    MongooseModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        uri: config.get<string>('MONGO_URI'),
      }),
    }),
    ScheduleModule.forRoot(),
    AuthModule,
    UsersModule,
    BloodCentersModule,
    BloodInventoryModule,
    DonationsModule,
    NotificationsModule,
    AppointmentsModule,
    ShortageEngineModule,
  ],
})
export class AppModule {}
