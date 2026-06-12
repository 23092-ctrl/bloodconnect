import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { BloodInventory, BloodInventorySchema } from './schemas/blood-inventory.schema';
import { BloodInventoryService } from './blood-inventory.service';
import { BloodInventoryController } from './blood-inventory.controller';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: BloodInventory.name, schema: BloodInventorySchema },
    ]),
  ],
  controllers: [BloodInventoryController],
  providers: [BloodInventoryService],
  exports: [BloodInventoryService],
})
export class BloodInventoryModule {}
