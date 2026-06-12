import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Public } from '../../common/decorators/public.decorator';
import { Role } from '../../common/enums/role.enum';
import { BloodInventoryService } from './blood-inventory.service';
import { UpdateInventoryDto } from './dto/update-inventory.dto';

@ApiTags('Blood Inventory')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('blood-inventory')
export class BloodInventoryController {
  constructor(private readonly service: BloodInventoryService) {}

  @Post(':centerId')
  @Roles(Role.ADMIN, Role.CENTER_ADMIN)
  upsert(@Param('centerId') centerId: string, @Body() dto: UpdateInventoryDto) {
    return this.service.upsert(centerId, dto);
  }

  @Public()
  @Get('center/:centerId')
  findByCenterId(@Param('centerId') centerId: string) {
    return this.service.findByCenterId(centerId);
  }

  @Public()
  @Get('summary/global')
  getGlobalSummary() {
    return this.service.getGlobalSummary();
  }

  @Get('shortages/detect')
  @Roles(Role.ADMIN)
  detectShortages() {
    return this.service.detectShortages();
  }
}
