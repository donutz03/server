import {Contains,IsInt,IsOptional,IsString,Min,MinLength} from 'class-validator';

export class ProductModel{



  @IsOptional()
  @IsInt()
  @IsPositive()
  id: number;
  
  @MinLength(5)
  @IsString()
  name: string;

  @IsNumber()
  @IsPositive()
  @Min(1000)
  quantity: number;

  @IsNumber()
  @IsPositive()
  @Min(1)
  price: number;
  
  @IsString()
  @Contains('SC')
  @MinLength(10)
  price:number;
  
  @IsString()
  @Contains('SC')
  @MinLength(10)
  vendor:string;
  constructor(obj:any) {
    Object.assign(this,obj);
  }
}
