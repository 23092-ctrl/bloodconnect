import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsMongoId, IsNotEmpty, IsNumber, IsOptional, IsString, Min } from 'class-validator';
import { BloodType } from '../../../common/enums/blood-type.enum';

export class CreateDonationDto {
  @ApiProperty()
  @IsMongoId()
  centerId: string;

  @ApiProperty({ enum: BloodType })
  @IsEnum(BloodType)
  @IsNotEmpty()
  bloodType: BloodType;

  @ApiPropertyOptional({ default: 1 })
  @IsNumber()
  @Min(1)
  @IsOptional()
  units?: number;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  notes?: string;

  @ApiPropertyOptional({ description: 'Donor ID — used by center_admin to record on behalf of a donor' })
  @IsMongoId()
  @IsOptional()
  donorId?: string;

  @ApiPropertyOptional({ description: 'Donor email — alternative to donorId for center_admin lookup' })
  @IsString()
  @IsOptional()
  donorEmail?: string;
}
