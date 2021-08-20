@IsTest
public with sharing class Utils_Test {

    private static testMethod void testSplitCsv() {
        System.assertEquals(new List<String>(), Utils.splitCsv(null));
        System.assertEquals(new List<String>(), Utils.splitCsv(''));
        System.assertEquals(new List<String>{'a'}, Utils.splitCsv('a'));
        System.assertEquals(new List<String>{'a'}, Utils.splitCsv('a,'));
        System.assertEquals(new List<String>{'a'}, Utils.splitCsv('a;'));
        System.assertEquals(new List<String>{'a'}, Utils.splitCsv('a; '));
        System.assertEquals(new List<String>{'a'}, Utils.splitCsv('a, '));
        System.assertEquals(new List<String>{'a','b'}, Utils.splitCsv('a, b'));
        System.assertEquals(new List<String>{'a','b'}, Utils.splitCsv('a; b'));
        System.assertEquals(new List<String>{'a','b'}, Utils.splitCsv('a; b '));
        System.assertEquals(new List<String>{'a','b'}, Utils.splitCsv(' a; b '));
    }

}
