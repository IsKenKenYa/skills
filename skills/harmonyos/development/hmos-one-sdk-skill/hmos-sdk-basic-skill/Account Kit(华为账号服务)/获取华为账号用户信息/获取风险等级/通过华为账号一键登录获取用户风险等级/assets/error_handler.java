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

public class ErrorHandler {
    
    public static void handleClientError(int errorCode, String errorMsg) {
        System.err.println("客户端错误: " + errorCode + " - " + errorMsg);
        
        switch (errorCode) {
            case 1001502001:
                System.out.println("处理方案: 提示用户登录华为账号并重试");
                break;
            case 1001502005:
                System.out.println("处理方案: 提示用户检查网络状态并重试");
                break;
            case 1001502009:
                System.out.println("处理方案: 提示用户尝试使用其他方式登录");
                break;
            case 1001502012:
                System.out.println("处理方案: 提示用户授权后重试");
                break;
            case 1001502014:
                System.out.println("处理方案: 完成riskLevel scope权限申请，发送邮件至accountkit@huawei.com");
                break;
            case 12300001:
                System.out.println("处理方案: 提示用户稍后重试");
                break;
            case 1005300001:
                System.out.println("处理方案: 提示用户同意协议后重试");
                break;
            default:
                System.out.println("处理方案: 提示用户使用其他方式登录");
                break;
        }
    }
    
    public static void handleServerError(int errCode, String errMsg) {
        System.err.println("服务端错误: " + errCode + " - " + errMsg);
        
        switch (errCode) {
            case 6:
                System.out.println("处理方案: 会话失效，需要刷新Access Token或重新授权");
                break;
            case 403:
                System.out.println("处理方案: 无权访问，前往AGC申请riskLevel scope权限");
                break;
            case 503:
                System.out.println("处理方案: 触发系统流控，稍后重试");
                break;
            case 70001201:
                System.out.println("处理方案: 请求参数错误，检查请求参数格式");
                break;
            case 70001402:
                System.out.println("处理方案: 系统鉴权错误，稍后重试或提交问题反馈");
                break;
            case 70020002:
                System.out.println("处理方案: 接口内部超时，稍后重试");
                break;
            case 70001401:
                System.out.println("处理方案: 接口内部错误，根据错误描述处理或提交问题反馈");
                break;
            default:
                System.out.println("处理方案: 未知错误，查看错误描述: " + errMsg);
                break;
        }
    }
    
    public static void handleHttpError(int statusCode) {
        System.err.println("HTTP错误: " + statusCode);
        
        switch (statusCode) {
            case 400:
                System.out.println("处理方案: 参数错误，检查请求参数是否符合规范");
                break;
            case 403:
                System.out.println("处理方案: 无权限访问，检查网络环境配置和权限申请");
                break;
            case 404:
                System.out.println("处理方案: 找不到服务，检查请求URI是否正确");
                break;
            case 405:
                System.out.println("处理方案: 不支持的http请求method，检查http请求method");
                break;
            case 415:
                System.out.println("处理方案: 不支持的媒体类型，检查contentType是否正确");
                break;
            case 500:
                System.out.println("处理方案: 服务内部错误，提交问题反馈");
                break;
            case 502:
                System.out.println("处理方案: 请求连接异常，稍后重试");
                break;
            case 504:
                System.out.println("处理方案: 请求连接超时，稍后重试");
                break;
            default:
                System.out.println("处理方案: 其他HTTP错误，检查网络连接");
                break;
        }
    }
    
    public static JSONObject refreshToken(String refreshToken, String clientId, String clientSecret) throws IOException {
        CloseableHttpClient httpClient = HttpClients.createDefault();
        HttpPost httpPost = new HttpPost("https://oauth-login.cloud.huawei.com/oauth2/v3/token");
        
        List<NameValuePair> params = new ArrayList<>();
        params.add(new BasicNameValuePair("grant_type", "refresh_token"));
        params.add(new BasicNameValuePair("refresh_token", refreshToken));
        params.add(new BasicNameValuePair("client_id", clientId));
        params.add(new BasicNameValuePair("client_secret", clientSecret));
        
        httpPost.setEntity(new UrlEncodedFormEntity(params));
        
        String responseBody = EntityUtils.toString(httpClient.execute(httpPost).getEntity());
        JSONObject result = JSONObject.parseObject(responseBody);
        
        httpClient.close();
        return result;
    }
    
    public static void fallbackToOtherLogin() {
        System.out.println("降级方案: 使用其他登录方式");
        System.out.println("建议:");
        System.out.println("1. 提示用户使用手机号登录");
        System.out.println("2. 提示用户使用邮箱登录");
        System.out.println("3. 提示用户使用第三方账号登录");
    }
    
    public static void retryAfterDelay(int retryCount, int maxRetries) {
        if (retryCount < maxRetries) {
            System.out.println("重试方案: 等待" + (retryCount * 2) + "秒后重试");
            try {
                Thread.sleep(retryCount * 2000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        } else {
            System.out.println("达到最大重试次数，使用降级方案");
            fallbackToOtherLogin();
        }
    }
}