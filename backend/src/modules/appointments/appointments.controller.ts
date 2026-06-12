import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Request,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '../../common/enums/role.enum';
import { AppointmentsService } from './appointments.service';
import { CreateAppointmentDto } from './dto/create-appointment.dto';

@ApiTags('Appointments')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('appointments')
export class AppointmentsController {
  constructor(private readonly service: AppointmentsService) {}

  @Post()
  @Roles(Role.DONOR)
  create(@Request() req, @Body() dto: CreateAppointmentDto) {
    return this.service.create(req.user.sub, dto);
  }

  @Get('my')
  @Roles(Role.DONOR)
  getMyAppointments(@Request() req) {
    return this.service.findByDonor(req.user.sub);
  }

  @Get('center/:centerId')
  @Roles(Role.ADMIN, Role.CENTER_ADMIN)
  findByCenter(
    @Param('centerId') centerId: string,
    @Query('status') status?: string,
  ) {
    return this.service.findByCenter(centerId, status);
  }

  @Patch(':id/confirm')
  @Roles(Role.ADMIN, Role.CENTER_ADMIN)
  confirm(@Param('id') id: string) {
    return this.service.confirm(id);
  }

  @Patch(':id/complete')
  @Roles(Role.ADMIN, Role.CENTER_ADMIN)
  complete(@Param('id') id: string) {
    return this.service.complete(id);
  }

  @Patch(':id/reject')
  @Roles(Role.ADMIN, Role.CENTER_ADMIN)
  reject(@Param('id') id: string, @Body('reason') reason?: string) {
    return this.service.reject(id, reason);
  }

  @Patch(':id/cancel')
  @Roles(Role.DONOR)
  cancel(@Request() req, @Param('id') id: string) {
    return this.service.cancel(id, req.user.sub);
  }
}
