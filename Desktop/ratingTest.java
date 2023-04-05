
package com.example.onlinebiz;

import model.Product;
import model.Rating;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * RatingTest class is used to test the implemented
 * Rating class functionalities namely such as increasing
 * the count of ratings received, increase the total of the ratings
 * received and returning the correct average rating of a product
 *
 * @author Hodoroaga Ionut
 *
 */

public class RatingTest {

    private Rating ratingOne;
    
    private Rating ratingTwo;

    private Product productOne;

    private Product productTwo;


    @BeforeEach
    void setup(){
        ratingOne = new Rating();
        ratingTwo = new Rating();
        productOne = new Product();
        productTwo = new Product();
    }
    
    @Test
    @DisplayName("Check that ratings count increases when a user leaves a rating")
    void ratingsCountCheck() {
        



       
    }

}