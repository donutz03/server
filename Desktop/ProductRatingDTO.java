
package dto;

        import lombok.*;
        import org.hibernate.validator.constraints.URL;
        import javax.validation.constraints.NotNull;
        import javax.validation.constraints.PositiveOrZero;
        import javax.validation.constraints.Size;
        import java.util.Map;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Data
public class ProductRatingDTO {

 @PositiveOrZero
    private int id;

@NotNull(message = "Product cannot be null")
    private String product;

@PositiveOrZero
    private double rating;

}


