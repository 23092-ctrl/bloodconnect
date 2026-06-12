import { Controller, Get, Param, Patch, Query, Request, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { NotificationsService } from './notifications.service';

@ApiTags('Notifications')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly service: NotificationsService) {}

  @Get()
  findMyNotifications(
    @Request() req,
    @Query('page') page: number,
    @Query('limit') limit: number,
  ) {
    return this.service.findByUser(req.user.sub, page, limit);
  }

  @Patch(':id/read')
  markRead(@Request() req, @Param('id') id: string) {
    return this.service.markRead(req.user.sub, id);
  }

  @Patch('read-all')
  markAllRead(@Request() req) {
    return this.service.markAllRead(req.user.sub);
  }
}
