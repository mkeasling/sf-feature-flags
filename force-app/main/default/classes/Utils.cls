public with sharing class Utils {

    public static List<String> splitCsv(String str) {
        if(String.isBlank(str)) return new List<String>();
        return str.trim().split('[,;]\\s*');
    }

    public class AppException extends Exception {}

}
