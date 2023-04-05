package model;

import lombok.AllArgsConstructor;
import lombok.Generated;
import lombok.Getter;
import lombok.Setter;

import java.util.Arrays;
@AllArgsConstructor
@Getter
@Setter
public class ShoppingCart {

	protected Vector productsInTheShoppingCart;	
	protected int totalCostOfProducts;	

	public ShoppingCart()
	{
		products = new Vector();
		totalCostOfProducts = 0;
	}


	public void addProduct(Product product)
	{

	}


	public void removeProduct(Product product)
	{

	}


	public Product[] getProducts()
	{
	Product[] productArray = 
		new Product[products.size()];

	products.copyInto(productArray);

	return productArray;
	}
}
