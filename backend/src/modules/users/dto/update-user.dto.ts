import { PartialType, OmitType } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { CreateUserDto } from './create-user.dto';

export class UpdateUserDto extends PartialType(
  OmitType(CreateUserDto, ['email', 'password'] as const),
) {
  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  address?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  fcmToken?: string;

  @ApiPropertyOptional()
  @IsOptional()
  notificationsEnabled?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  medicallyEligible?: boolean;
}
