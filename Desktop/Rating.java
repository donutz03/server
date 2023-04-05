package model;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

import java.util.HashMap;

/**
 * Rating is an entity we'll be using to
 * store information about the ratings of products.
 * Every product will have a default rating of 0 stars.
 * The rating of a product is the average of all ratings
 * received from users.
 *
 * @author Hodoroaga Ionut
 *
 */

@AllArgsConstructor
@Getter
@Setter

public class Rating {

    private int ratingsCount;

    private int ratingsTotal;

    private HashMap<Product, Double> ratings;
    private HashMap<Product, Integer> totalRatings;
    private HashMap<Product, Integer> countRatings;

    public Rating() {
        this.ratingsCount = 0;
        this.ratingsTotal = 0;
        ratings = new HashMap<>();
        totalRatings = new HashMap<>();
        countRatings = new HashMap<>();
    }

    public void ratingsTotal(Product product, int rating)
    {
        this.ratingsTotal = this.ratingsTotal + rating;
        this.ratingsCount = ratingsCount + 1;
        totalRatings.put(product, ratingsTotal);
        countRatings.put(product, ratingsCount);
    }

    public void averageRating(Product product) {
        // check to see if there have been ratings
        // if so, calculate the average and assign to ratingsAverage
        // if not, leave ratingsAverage at 0.0

        if (ratingsCount > 0) {
            double myRating = (double) this.ratingsTotal / (double) this.ratingsCount;
            ratings.put(product, myRating);
        } else {
            ratings.put(product, 0.0);
        }
    }

}
