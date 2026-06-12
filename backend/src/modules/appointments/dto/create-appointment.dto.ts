import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsEnum, IsMongoId, IsOptional, IsString } from 'class-validator';
import { BloodType } from '../../../common/enums/blood-type.enum';

export class CreateAppointmentDto {
  @ApiProperty()
  @IsMongoId()
  centerId: string;

  @ApiProperty({ enum: BloodType })
  @IsEnum(BloodType)
  bloodType: BloodType;

  @ApiPropertyOptional({ example: '2026-06-15T09:00:00.000Z' })
  @IsDateString()
  @IsOptional()
  scheduledDate?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  notes?: string;
}
