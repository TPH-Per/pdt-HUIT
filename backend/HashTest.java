import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

public class HashTest {
    public static void main(String[] args) {
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
        String rawPassword = "123456";
        String hash = "$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy";
        
        boolean matches = encoder.matches(rawPassword, hash);
        System.out.println("Hash matches '123456': " + matches);
        
        // Also show what the correct hash for "123456" should be
        String correctHash = encoder.encode(rawPassword);
        System.out.println("Correct hash for '123456': " + correctHash);
    }
}
