import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { BloodCenter, BloodCenterSchema } from './schemas/blood-center.schema';
import { BloodCentersService } from './blood-centers.service';
import { BloodCentersController } from './blood-centers.controller';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: BloodCenter.name, schema: BloodCenterSchema }]),
  ],
  controllers: [BloodCentersController],
  providers: [BloodCentersService],
  exports: [BloodCentersService],
})
export class BloodCentersModule {}
