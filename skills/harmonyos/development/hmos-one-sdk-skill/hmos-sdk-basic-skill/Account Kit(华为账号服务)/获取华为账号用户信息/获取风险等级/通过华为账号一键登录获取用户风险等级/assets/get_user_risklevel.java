import com.alibaba.fastjson2.JSONArray;
import com.alibaba.fastjson2.JSONObject;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

public class GetUserRiskLevelDemo {
    private static final String TOKEN_URL = "https://oauth-login.cloud.huawei.com/oauth2/v3/token";
    private static final String RISK_LEVEL_URL = "https://account.cloud.huawei.com/user/getuserrisklevel";
    
    public static void main(String[] args) {
        try {
            String clientId = "<Your Client ID>";
            String clientSecret = "<Your Client Secret>";
            String authorizationCode = "<Authorization Code from Client>";
            String transactionID = generateTransactionID();
            String scene = "registration"; // 或 "marketing"
            
            JSONObject tokenResult = getAccessToken(authorizationCode, clientId, clientSecret);
            String accessToken = tokenResult.getString("access_token");
            String refreshToken = tokenResult.getString("refresh_token");
            
            JSONObject riskLevelResult = getUserRiskLevel(accessToken, clientId, transactionID, scene);
            handleRiskLevelResult(riskLevelResult);
            
        } catch (Exception e) {
            System.err.println("获取用户风险等级失败: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    public static JSONObject getAccessToken(String authorizationCode, String clientId, String clientSecret) throws IOException {
        CloseableHttpClient httpClient = HttpClients.createDefault();
        HttpPost httpPost = new HttpPost(TOKEN_URL);
        
        Map<String, String> params = new HashMap<>();
        params.put("grant_type", "authorization_code");
        params.put("code", authorizationCode);
        params.put("client_id", clientId);
        params.put("client_secret", clientSecret);
        
        StringEntity entity = new StringEntity(buildFormParams(params));
        entity.setContentType("application/x-www-form-urlencoded");
        httpPost.setEntity(entity);
        
        CloseableHttpResponse response = httpClient.execute(httpPost);
        String responseBody = EntityUtils.toString(response.getEntity());
        
        JSONObject result = JSONObject.parseObject(responseBody);
        
        if (result.containsKey("error")) {
            throw new IOException("获取Access Token失败: " + result.getString("error_description"));
        }
        
        httpClient.close();
        return result;
    }
    
    public static JSONObject getUserRiskLevel(String accessToken, String clientId, String transactionID, String scene) throws IOException {
        CloseableHttpClient httpClient = HttpClients.createDefault();
        
        String urlWithParams = RISK_LEVEL_URL + "?clientID=" + clientId + "&transactionID=" + transactionID;
        HttpPost httpPost = new HttpPost(urlWithParams);
        
        Map<String, String> requestBody = new HashMap<>();
        requestBody.put("accessToken", accessToken);
        requestBody.put("scene", scene);
        
        StringEntity entity = new StringEntity(JSONObject.toJSONString(requestBody));
        entity.setContentType("application/json;charset=utf-8");
        httpPost.setEntity(entity);
        
        CloseableHttpResponse response = httpClient.execute(httpPost);
        String responseBody = EntityUtils.toString(response.getEntity());
        
        JSONObject result = JSONObject.parseObject(responseBody);
        
        httpClient.close();
        return result;
    }
    
    public static void handleRiskLevelResult(JSONObject result) {
        Integer errCode = result.getInteger("errCode");
        String errMsg = result.getString("errMsg");
        
        if (errCode != null && errCode != 0) {
            System.err.println("获取风险等级失败: errCode=" + errCode + ", errMsg=" + errMsg);
            handleRiskLevelError(errCode, errMsg);
            return;
        }
        
        Integer riskLevel = result.getInteger("riskLevel");
        JSONArray riskTag = result.getJSONArray("riskTag");
        
        System.out.println("风险等级: " + riskLevel);
        System.out.println("风险等级描述: " + getRiskLevelDescription(riskLevel));
        
        if (riskTag != null && riskTag.size() > 0) {
            System.out.println("风险标签: " + riskTag.toJSONString());
            handleRiskTags(riskTag);
        }
        
        provideSuggestion(riskLevel);
    }
    
    public static String getRiskLevelDescription(Integer level) {
        if (level == null) return "未知";
        
        switch (level) {
            case 0: return "未发现显著风险";
            case 1: return "低风险";
            case 2: return "中风险";
            case 3: return "高风险";
            case 4: return "风险未知";
            default: return "未知风险等级";
        }
    }
    
    public static void handleRiskTags(JSONArray riskTags) {
        for (int i = 0; i < riskTags.size(); i++) {
            String tag = riskTags.getString(i);
            System.out.println("风险标签[" + i + "]: " + getRiskTagDescription(tag));
        }
    }
    
    public static String getRiskTagDescription(String tag) {
        switch (tag) {
            case "spamMailbox": return "绑定垃圾邮箱";
            case "riskPhoneNumber": return "绑定卡商手机号";
            case "riskDevice": return "使用风险设备";
            case "ipCluster": return "IP聚集";
            case "deviceCluster": return "设备聚集";
            case "batchBehavior": return "批量操作";
            case "illegalLogin": return "非法登录";
            case "activityFraud": return "恶意行为-薅羊毛";
            default: return "未知风险标签: " + tag;
        }
    }
    
    public static void provideSuggestion(Integer riskLevel) {
        if (riskLevel == null) return;
        
        System.out.println("\n建议处置方案:");
        switch (riskLevel) {
            case 0:
                System.out.println("建议确认无风险后放通");
                break;
            case 1:
                System.out.println("建议进行简单验证（如验证码、短信等），或人工审核");
                break;
            case 2:
                System.out.println("建议根据业务场景采取一定措施规避伤害");
                System.out.println("例如：营销活动可降低高等级奖励的概率、打榜类活动对此类投票降低权重、登录注册要求二次验证等");
                break;
            case 3:
                System.out.println("建议业务逻辑直接拦截");
                System.out.println("例如：红包类活动返回不中奖或最小额红包、打榜类活动不计算票数、登录/注册操作要求二次验证");
                break;
            case 4:
                System.out.println("建议结合账号历史行为及业务场景做出最终决策");
                break;
        }
    }
    
    public static void handleRiskLevelError(Integer errCode, String errMsg) {
        System.err.println("错误处理建议:");
        switch (errCode) {
            case 6:
                System.err.println("会话失效，请使用Refresh Token刷新Access Token或重新授权");
                break;
            case 403:
                System.err.println("无权访问，请前往AGC申请riskLevel scope权限");
                break;
            case 503:
                System.err.println("触发系统流控，请稍后重试");
                break;
            case 70001201:
                System.err.println("请求参数错误，请检查请求参数格式");
                break;
            case 70001402:
                System.err.println("系统鉴权错误，请稍后重试或提交问题反馈");
                break;
            case 70020002:
                System.err.println("接口内部超时，请稍后重试");
                break;
            case 70001401:
                System.err.println("接口内部错误，请根据错误描述处理或提交问题反馈");
                break;
            default:
                System.err.println("未知错误，请查看错误描述: " + errMsg);
                break;
        }
    }
    
    public static String generateTransactionID() {
        long timestamp = System.currentTimeMillis();
        String random = String.valueOf((int)(Math.random() * 900000000) + 100000000);
        return String.format("%d%s", timestamp, random);
    }
    
    public static String buildFormParams(Map<String, String> params) {
        StringBuilder sb = new StringBuilder();
        for (Map.Entry<String, String> entry : params.entrySet()) {
            if (sb.length() > 0) sb.append("&");
            sb.append(entry.getKey()).append("=").append(entry.getValue());
        }
        return sb.toString();
    }
}