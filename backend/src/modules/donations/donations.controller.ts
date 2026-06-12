import { Body, Controller, Get, Param, Post, Query, Request, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '../../common/enums/role.enum';
import { DonationsService } from './donations.service';
import { CreateDonationDto } from './dto/create-donation.dto';

@ApiTags('Donations')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('donations')
export class DonationsController {
  constructor(private readonly service: DonationsService) {}

  @Post()
  create(@Request() req, @Body() dto: CreateDonationDto) {
    return this.service.createWithLookup(req.user.sub, dto);
  }

  @Get('my')
  getMyDonations(
    @Request() req,
    @Query('page') page: number,
    @Query('limit') limit: number,
  ) {
    return this.service.findByDonor(req.user.sub, page, limit);
  }

  @Get('my/stats')
  getMyStats(@Request() req) {
    return this.service.getDonorStats(req.user.sub);
  }

  @Get('center/:centerId')
  @Roles(Role.ADMIN, Role.CENTER_ADMIN)
  findByCenter(
    @Param('centerId') centerId: string,
    @Query('page') page: number,
    @Query('limit') limit: number,
  ) {
    return this.service.findByCenter(centerId, page, limit);
  }
}
