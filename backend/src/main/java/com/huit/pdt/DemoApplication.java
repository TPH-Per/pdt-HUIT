package com.huit.pdt;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.util.TimeZone;
import jakarta.annotation.PostConstruct;

@SpringBootApplication
public class DemoApplication {

	public static void main(String[] args) {
		// Set default timezone to UTC to avoid PostgreSQL timezone issues
		TimeZone.setDefault(TimeZone.getTimeZone("UTC"));
		SpringApplication.run(DemoApplication.class, args);
	}

	@PostConstruct
	public void init() {
		// Ensure timezone is set for the application context
		TimeZone.setDefault(TimeZone.getTimeZone("UTC"));
	}

}








