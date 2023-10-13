import { MinLength, MaxLength } from 'class-validator';

export class Post {
@MinLength(10, {
  message: 'Title is too short. Minimal length is $constraint1 characters, but actual is $value',
})
  
  @MaxLength(50, {
    message:'Title is too long. Maximal length is $constraint1 characters, buyt actual is $value',
  })
  title: string;
}
