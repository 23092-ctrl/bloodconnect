import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsNumber, IsOptional, Min } from 'class-validator';
import { BloodType } from '../../../common/enums/blood-type.enum';

export class UpdateInventoryDto {
  @ApiProperty({ enum: BloodType })
  @IsEnum(BloodType)
  @IsNotEmpty()
  bloodType: BloodType;

  @ApiProperty()
  @IsNumber()
  @Min(0)
  availableUnits: number;

  @ApiPropertyOptional()
  @IsNumber()
  @Min(0)
  @IsOptional()
  safeThreshold?: number;

  @ApiPropertyOptional()
  @IsNumber()
  @Min(0)
  @IsOptional()
  criticalThreshold?: number;
}
