import {
  IsEmail,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MinLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { BloodType } from '../../../common/enums/blood-type.enum';

export class CreateUserDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  fullName: string;

  @ApiProperty()
  @IsEmail()
  email: string;

  @ApiProperty({ minLength: 8 })
  @IsString()
  @MinLength(8)
  password: string;

  @ApiPropertyOptional({ enum: BloodType })
  @IsEnum(BloodType)
  @IsOptional()
  bloodType?: BloodType;

  @ApiPropertyOptional({ enum: ['male', 'female'] })
  @IsEnum(['male', 'female'])
  @IsOptional()
  gender?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  phone?: string;
}
