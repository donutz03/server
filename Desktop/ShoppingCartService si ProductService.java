package com.example.onlinebiz.service;

import com.example.onlinebiz.dto.ProductDTO;
import com.example.onlinebiz.model.Category;
import lombok.RequiredArgsConstructor;
import com.example.onlinebiz.model.Product;
import org.springframework.stereotype.Service;
import com.example.onlinebiz.persistence.ProductRepository;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ProductService {

    private final ProductRepository productRepository;

    public static ProductDTO getDtoFromProduct(Product product) {

        return new ProductDTO(product);
    }

    public static Product getProductFromDto(ProductDTO productDto, Category category) {

        return new Product(productDto, category);
    }

    public List<ProductDTO> listProducts() {

        List<Product> products = productRepository.findAll();

        return products.stream()
                .map(ProductService::getDtoFromProduct)
                .collect(Collectors.toList());
    }

    public void addProduct(ProductDTO productDto, Category category) {

        Product product = getProductFromDto(productDto, category);

        productRepository.save(product);
    }

    public void updateProduct(int productID, ProductDTO productDto, Category category) {

        Product product = getProductFromDto(productDto, category);

        product.setId(productID);

        productRepository.save(product);
    }

    public Optional<Product> getProductById(int productID) {

        return productRepository.findById(productID);
    }

    public Optional<Product> findByDescription(String description) {

        return productRepository.findByDescriptionLike(description);
    }

    public Optional<Product> findProductByNameLike(String name) {

        return productRepository.findByName(name);
    }

    public List<Product> findProductByCategoryLike(String category) {

        return productRepository.findByCategoryLike(category);
    }

    public List<Product> findProductByPriceBetween(double minPrice, double maxPrice) {

        return productRepository.findByPriceBetween(minPrice, maxPrice);
    }

    public List<Product> findProductByPriceGreaterThan(double minPrice) {

        return productRepository.findByPriceGreaterThan(minPrice);
    }

    public List<Product> findProductByPriceLessThan(double maxPrice) {

        return productRepository.findByPriceLessThan(maxPrice);
    }
}



// de aici in sus shoppingcartservice
// de aici in jos product service

package com.example.onlinebiz.service;

import com.example.onlinebiz.dto.ProductDTO;
import com.example.onlinebiz.model.Category;
import lombok.RequiredArgsConstructor;
import com.example.onlinebiz.model.Product;
import org.springframework.stereotype.Service;
import com.example.onlinebiz.persistence.ProductRepository;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ProductService {

    private final ProductRepository productRepository;

    public static ProductDTO getDtoFromProduct(Product product) {

        return new ProductDTO(product);
    }

    public static Product getProductFromDto(ProductDTO productDto, Category category) {

        return new Product(productDto, category);
    }

    public List<ProductDTO> listProducts() {

        List<Product> products = productRepository.findAll();

        return products.stream()
                .map(ProductService::getDtoFromProduct)
                .collect(Collectors.toList());
    }

    public void addProduct(ProductDTO productDto, Category category) {

        Product product = getProductFromDto(productDto, category);

        productRepository.save(product);
    }

    public void updateProduct(int productID, ProductDTO productDto, Category category) {

        Product product = getProductFromDto(productDto, category);

        product.setId(productID);

        productRepository.save(product);
    }

    public Optional<Product> getProductById(int productID) {

        return productRepository.findById(productID);
    }

    public Optional<Product> findByDescription(String description) {

        return productRepository.findByDescriptionLike(description);
    }

    public Optional<Product> findProductByNameLike(String name) {

        return productRepository.findByName(name);
    }

    public List<Product> findProductByCategoryLike(String category) {

        return productRepository.findByCategoryLike(category);
    }

    public List<Product> findProductByPriceBetween(double minPrice, double maxPrice) {

        return productRepository.findByPriceBetween(minPrice, maxPrice);
    }

    public List<Product> findProductByPriceGreaterThan(double minPrice) {

        return productRepository.findByPriceGreaterThan(minPrice);
    }

    public List<Product> findProductByPriceLessThan(double maxPrice) {

        return productRepository.findByPriceLessThan(maxPrice);
    }
}
