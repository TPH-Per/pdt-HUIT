package com.huit.pdt;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

import java.util.TimeZone;

@SpringBootTest
class DemoApplicationTests {

	static {
		// Set default timezone to UTC to avoid PostgreSQL timezone issues with Asia/Saigon
		TimeZone.setDefault(TimeZone.getTimeZone("UTC"));
	}

	@Test
	void contextLoads() {
	}

}

