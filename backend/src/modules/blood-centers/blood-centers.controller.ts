import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiQuery, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Public } from '../../common/decorators/public.decorator';
import { Role } from '../../common/enums/role.enum';
import { BloodCentersService } from './blood-centers.service';
import { CreateBloodCenterDto } from './dto/create-blood-center.dto';

@ApiTags('Blood Centers')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('blood-centers')
export class BloodCentersController {
  constructor(private readonly service: BloodCentersService) {}

  @Post()
  @Roles(Role.ADMIN)
  create(@Body() dto: CreateBloodCenterDto) {
    return this.service.create(dto);
  }

  @Public()
  @Get()
  findAll(@Query('page') page: number, @Query('limit') limit: number) {
    return this.service.findAll(page, limit);
  }

  @Public()
  @Get('nearest')
  @ApiQuery({ name: 'lng', type: Number })
  @ApiQuery({ name: 'lat', type: Number })
  @ApiQuery({ name: 'radius', type: Number, required: false })
  findNearest(
    @Query('lng') lng: number,
    @Query('lat') lat: number,
    @Query('radius') radius?: number,
  ) {
    return this.service.findNearest(+lng, +lat, radius ? +radius : 50);
  }

  @Public()
  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.service.findById(id);
  }

  @Patch(':id')
  @Roles(Role.ADMIN)
  update(@Param('id') id: string, @Body() dto: Partial<CreateBloodCenterDto>) {
    return this.service.update(id, dto);
  }

  @Patch(':id/verify')
  @Roles(Role.ADMIN)
  verify(@Param('id') id: string) {
    return this.service.verify(id);
  }
}
