import com.alibaba.fastjson2.JSONObject;
import org.apache.http.NameValuePair;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.message.BasicNameValuePair;
import org.apache.http.util.EntityUtils;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class TokenRefreshDemo {
    private static final String TOKEN_URL = "https://oauth-login.cloud.huawei.com/oauth2/v3/token";
    
    public static void main(String[] args) {
        try {
            String clientId = "<Your Client ID>";
            String clientSecret = "<Your Client Secret>";
            String refreshToken = "<Your Refresh Token>";
            
            JSONObject newTokens = refreshAccessToken(refreshToken, clientId, clientSecret);
            
            String newAccessToken = newTokens.getString("access_token");
            String newRefreshToken = newTokens.getString("refresh_token");
            Integer expiresIn = newTokens.getInteger("expires_in");
            
            System.out.println("新Access Token: " + newAccessToken);
            System.out.println("新Refresh Token: " + newRefreshToken);
            System.out.println("有效期: " + expiresIn + "秒");
            
        } catch (Exception e) {
            System.err.println("刷新Token失败: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    public static JSONObject refreshAccessToken(String refreshToken, String clientId, String clientSecret) throws IOException {
        CloseableHttpClient httpClient = HttpClients.createDefault();
        HttpPost httpPost = new HttpPost(TOKEN_URL);
        
        List<NameValuePair> params = new ArrayList<>();
        params.add(new BasicNameValuePair("grant_type", "refresh_token"));
        params.add(new BasicNameValuePair("refresh_token", refreshToken));
        params.add(new BasicNameValuePair("client_id", clientId));
        params.add(new BasicNameValuePair("client_secret", clientSecret));
        
        httpPost.setHeader("Content-Type", "application/x-www-form-urlencoded");
        httpPost.setEntity(new UrlEncodedFormEntity(params));
        
        CloseableHttpResponse response = httpClient.execute(httpPost);
        String responseBody = EntityUtils.toString(response.getEntity());
        
        JSONObject result = JSONObject.parseObject(responseBody);
        
        if (result.containsKey("error")) {
            Integer error = result.getInteger("error");
            Integer subError = result.getInteger("sub_error");
            String errorDescription = result.getString("error_description");
            
            handleRefreshError(error, subError, errorDescription);
            throw new IOException("刷新Token失败: " + errorDescription);
        }
        
        httpClient.close();
        return result;
    }
    
    public static void handleRefreshError(Integer error, Integer subError, String errorDescription) {
        System.err.println("刷新Token错误: error=" + error + ", sub_error=" + subError + ", description=" + errorDescription);
        
        switch (error) {
            case 1101:
                if (subError == 20002 || subError == 20003) {
                    System.err.println("client_id格式不正确，检查client_id是否满足正则: ^[0-9]{1,64}$");
                }
                break;
            case 1102:
                if (subError == 20001) {
                    System.err.println("client_id为空，请传入正确的client_id参数");
                } else if (subError == 20151) {
                    System.err.println("refresh_token为空，请传入正确的refresh_token参数");
                } else if (subError == 20181) {
                    System.err.println("grant_type为空，请传入grant_type=refresh_token");
                }
                break;
            case 1103:
                if (subError == 20153) {
                    System.err.println("无效的refresh_token，请检查refresh_token是否正确");
                }
                break;
            case 1203:
                if (subError == 12303) {
                    System.err.println("client_id在系统不存在，请前往AGC确认client_id是否存在");
                } else if (subError == 12304) {
                    System.err.println("无效的client_secret，请检查client_id和client_secret是否匹配");
                }
                break;
            default:
                if (subError == 500) {
                    System.err.println("系统内部错误，请稍后重试或提交问题反馈");
                }
                break;
        }
        
        System.out.println("\n建议处理方案:");
        System.out.println("1. 检查client_id和client_secret是否正确");
        System.out.println("2. 检查refresh_token是否过期（180天有效期）");
        System.out.println("3. 若refresh_token已过期，引导用户重新授权");
    }
    
    public static boolean isRefreshTokenExpired(JSONObject errorResponse) {
        Integer error = errorResponse.getInteger("error");
        Integer subError = errorResponse.getInteger("sub_error");
        
        return error == 1103 && subError == 20153;
    }
    
    public static void handleExpiredRefreshToken() {
        System.err.println("Refresh Token已过期（180天有效期）");
        System.out.println("处理方案:");
        System.out.println("1. 通知客户端Refresh Token已过期");
        System.out.println("2. 引导用户重新授权获取新的Authorization Code");
        System.out.println("3. 使用新的Authorization Code获取新的Access Token和Refresh Token");
    }
}