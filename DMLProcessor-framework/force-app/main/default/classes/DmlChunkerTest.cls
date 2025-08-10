/**
 * Test class for DmlChunker
 * 
 * This test class covers all scenarios for the DmlChunker including:
 * - Chunking functionality with different sizes
 * - Record validation (homogeneous records)
 * - Edge cases (empty, null, single records)
 * - Optimal chunk size calculations
 * - Error handling for invalid scenarios
 * - Performance testing with large datasets
 * - Boundary conditions and edge cases
 * 
 * @author DML Utility Team
 * @version 1.0
 */
@IsTest
public class DmlChunkerTest {
    
    // ===== TEST DATA SETUP =====
    
    /**
     * Creates test accounts with meaningful data
     * @param count Number of accounts to create
     * @return List of test accounts
     */
    private static List<Account> createTestAccounts(Integer count) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i,
                Type = 'Customer',
                Industry = 'Technology',
                BillingStreet = '123 Test St',
                BillingCity = 'Test City',
                BillingState = 'CA',
                BillingPostalCode = '12345'
            ));
        }
        return accounts;
    }
    
    /**
     * Creates test contacts with meaningful data
     * @param count Number of contacts to create
     * @return List of test contacts
     */
    private static List<Contact> createTestContacts(Integer count) {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < count; i++) {
            contacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact ' + i,
                Email = 'test' + i + '@example.com',
                Phone = '555-123-' + String.valueOf(i).leftPad(4, '0')
            ));
        }
        return contacts;
    }
    
    /**
     * Asserts that the expected number of chunks exist with the given size
     * @param chunks List of chunks to check
     * @param expectedChunkSize Expected size of each chunk
     * @param message Assertion message
     */
    private static void assertChunkSizes(List<List<SObject>> chunks, Integer expectedChunkSize, String message) {
        for (Integer i = 0; i < chunks.size(); i++) {
            List<SObject> chunk = chunks[i];
            if (i == chunks.size() - 1) {
                // Last chunk can be smaller than expected size
                System.assert(chunk.size() <= expectedChunkSize, 
                    message + ' - Chunk ' + i + ' should not exceed expected size. Actual: ' + chunk.size() + ', Expected: ' + expectedChunkSize);
            } else {
                System.assertEquals(expectedChunkSize, chunk.size(), 
                    message + ' - Chunk ' + i + ' should have expected size');
            }
        }
    }
    
    // ===== CONSTRUCTOR TESTS =====
    
    @IsTest
    static void testDefaultConstructor() {
        // Act
        DmlChunker chunker = new DmlChunker();
        
        // Assert
        System.assertEquals(100, chunker.getChunkSize(), 'Default chunk size should be 100');
    }
    
    @IsTest
    static void testParameterizedConstructor() {
        // Arrange
        Integer customChunkSize = 50;
        
        // Act
        DmlChunker chunker = new DmlChunker(customChunkSize);
        
        // Assert
        System.assertEquals(customChunkSize, chunker.getChunkSize(), 'Chunk size should match constructor parameter');
    }
    
    @IsTest
    static void testParameterizedConstructorWithZero() {
        // Arrange
        Integer customChunkSize = 0;
        
        // Act & Assert
        try {
            DmlChunker chunker = new DmlChunker(customChunkSize);
            System.assert(false, 'Should have thrown exception for zero chunk size');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Chunk size must be greater than 0'), 'Should throw appropriate error message');
        }
    }
    
    @IsTest
    static void testParameterizedConstructorWithNegative() {
        // Arrange
        Integer customChunkSize = -10;
        
        // Act & Assert
        try {
            DmlChunker chunker = new DmlChunker(customChunkSize);
            System.assert(false, 'Should have thrown exception for negative chunk size');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Chunk size must be greater than 0'), 'Should throw appropriate error message');
        }
    }
    
    // ===== CHUNK SIZE TESTS =====
    
    @IsTest
    static void testSetChunkSize() {
        // Arrange
        DmlChunker chunker = new DmlChunker();
        Integer newChunkSize = 75;
        
        // Act
        DmlChunker result = chunker.setChunkSize(newChunkSize);
        
        // Assert
        System.assertEquals(chunker, result, 'Should return self for chaining');
        System.assertEquals(newChunkSize, chunker.getChunkSize(), 'Chunk size should be updated');
    }
    
    @IsTest
    static void testSetChunkSizeWithZero() {
        // Arrange
        DmlChunker chunker = new DmlChunker();
        
        // Act & Assert
        try {
            chunker.setChunkSize(0);
            System.assert(false, 'Should have thrown exception for zero chunk size');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Chunk size must be greater than 0'), 'Should throw appropriate error message');
        }
    }
    
    @IsTest
    static void testSetChunkSizeWithNegative() {
        // Arrange
        DmlChunker chunker = new DmlChunker();
        
        // Act & Assert
        try {
            chunker.setChunkSize(-5);
            System.assert(false, 'Should have thrown exception for negative chunk size');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Chunk size must be greater than 0'), 'Should throw appropriate error message');
        }
    }
    
    @IsTest
    static void testGetChunkSize() {
        // Arrange
        Integer expectedSize = 25;
        DmlChunker chunker = new DmlChunker(expectedSize);
        
        // Act
        Integer actualSize = chunker.getChunkSize();
        
        // Assert
        System.assertEquals(expectedSize, actualSize, 'Should return correct chunk size');
    }
    
    // ===== SPLIT TESTS =====
    
    @IsTest
    static void testSplitWithExactChunkSize() {
        // Arrange
        List<Account> accounts = createTestAccounts(100);
        DmlChunker chunker = new DmlChunker(100);
        
        // Act
        List<List<SObject>> chunks = chunker.split(accounts);
        
        // Assert
        System.assertEquals(1, chunks.size(), 'Should create exactly one chunk');
        System.assertEquals(100, chunks[0].size(), 'Chunk should contain all records');
    }
    
    @IsTest
    static void testSplitWithSmallerThanChunkSize() {
        // Arrange
        List<Account> accounts = createTestAccounts(50);
        DmlChunker chunker = new DmlChunker(100);
        
        // Act
        List<List<SObject>> chunks = chunker.split(accounts);
        
        // Assert
        System.assertEquals(1, chunks.size(), 'Should create exactly one chunk');
        System.assertEquals(50, chunks[0].size(), 'Chunk should contain all records');
    }
    
    @IsTest
    static void testSplitWithLargerThanChunkSize() {
        // Arrange
        List<Account> accounts = createTestAccounts(250);
        DmlChunker chunker = new DmlChunker(100);
        
        // Act
        List<List<SObject>> chunks = chunker.split(accounts);
        
        // Assert
        System.assertEquals(3, chunks.size(), 'Should create 3 chunks (2 full + 1 partial)');
        System.assertEquals(100, chunks[0].size(), 'First chunk should have 100 records');
        System.assertEquals(100, chunks[1].size(), 'Second chunk should have 100 records');
        System.assertEquals(50, chunks[2].size(), 'Third chunk should have 50 records');
    }
    
    @IsTest
    static void testSplitWithExactMultiple() {
        // Arrange
        List<Account> accounts = createTestAccounts(200);
        DmlChunker chunker = new DmlChunker(50);
        
        // Act
        List<List<SObject>> chunks = chunker.split(accounts);
        
        // Assert
        System.assertEquals(4, chunks.size(), 'Should create 4 chunks');
        assertChunkSizes(chunks, 50, 'All chunks should have 50 records');
    }
    
    @IsTest
    static void testSplitWithSingleRecord() {
        // Arrange
        List<Account> accounts = createTestAccounts(1);
        DmlChunker chunker = new DmlChunker(100);
        
        // Act
        List<List<SObject>> chunks = chunker.split(accounts);
        
        // Assert
        System.assertEquals(1, chunks.size(), 'Should create exactly one chunk');
        System.assertEquals(1, chunks[0].size(), 'Chunk should contain the single record');
    }
    
    @IsTest
    static void testSplitWithEmptyRecords() {
        // Arrange
        List<Account> accounts = new List<Account>();
        DmlChunker chunker = new DmlChunker(100);
        
        // Act
        List<List<SObject>> chunks = chunker.split(accounts);
        
        // Assert
        System.assertEquals(0, chunks.size(), 'Should return empty list for empty records');
    }
    
    @IsTest
    static void testSplitWithNullRecords() {
        // Arrange
        DmlChunker chunker = new DmlChunker(100);
        
        // Act & Assert
        try {
            List<List<SObject>> chunks = chunker.split(null);
            System.assert(false, 'Should have thrown exception for null records');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Records cannot be null'), 'Should throw appropriate error message');
        }
    }
    
    @IsTest
    static void testSplitWithCustomChunkSize() {
        // Arrange
        List<Account> accounts = createTestAccounts(75);
        DmlChunker chunker = new DmlChunker(25);
        
        // Act
        List<List<SObject>> chunks = chunker.split(accounts);
        
        // Assert
        System.assertEquals(3, chunks.size(), 'Should create 3 chunks');
        System.assertEquals(25, chunks[0].size(), 'First chunk should have 25 records');
        System.assertEquals(25, chunks[1].size(), 'Second chunk should have 25 records');
        System.assertEquals(25, chunks[2].size(), 'Third chunk should have 25 records');
    }
    
    // ===== VALIDATION TESTS =====
    
    @IsTest
    static void testValidateHomogeneousRecords() {
        // Arrange
        List<Account> accounts = createTestAccounts(5);
        DmlChunker chunker = new DmlChunker();
        
        // Act & Assert - Should not throw exception
        try {
            chunker.validateHomogeneousRecords(accounts);
            System.assert(true, 'Should not throw exception for homogeneous records');
        } catch (Exception e) {
            System.assert(false, 'Should not throw exception for homogeneous records: ' + e.getMessage());
        }
    }
    
    @IsTest
    static void testValidateHomogeneousRecordsWithMixedTypes() {
        // Arrange
        List<SObject> mixedRecords = new List<SObject>();
        mixedRecords.addAll(createTestAccounts(2));
        mixedRecords.addAll(createTestContacts(2));
        DmlChunker chunker = new DmlChunker();
        
        // Act & Assert
        try {
            chunker.validateHomogeneousRecords(mixedRecords);
            System.assert(false, 'Should have thrown exception for mixed record types');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('All records must be of the same type'), 'Should throw appropriate error message');
        }
    }
    
    @IsTest
    static void testValidateHomogeneousRecordsWithEmptyList() {
        // Arrange
        List<Account> accounts = new List<Account>();
        DmlChunker chunker = new DmlChunker();
        
        // Act & Assert - Should not throw exception
        try {
            chunker.validateHomogeneousRecords(accounts);
            System.assert(true, 'Should not throw exception for empty list');
        } catch (Exception e) {
            System.assert(false, 'Should not throw exception for empty list: ' + e.getMessage());
        }
    }
    
    @IsTest
    static void testValidateHomogeneousRecordsWithNull() {
        // Arrange
        DmlChunker chunker = new DmlChunker();
        
        // Act & Assert
        try {
            chunker.validateHomogeneousRecords(null);
            System.assert(false, 'Should have thrown exception for null records');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Records cannot be null'), 'Should throw appropriate error message');
        }
    }
    
    // ===== PERFORMANCE TESTS =====
    
    @IsTest
    static void testSplitWithLargeDataset() {
        // Arrange
        List<Account> accounts = createTestAccounts(1000);
        DmlChunker chunker = new DmlChunker(100);
        
        // Act
        List<List<SObject>> chunks = chunker.split(accounts);
        
        // Assert
        System.assertEquals(10, chunks.size(), 'Should create 10 chunks for 1000 records with chunk size 100');
        assertChunkSizes(chunks, 100, 'All chunks should have 100 records except the last');
        System.assertEquals(100, chunks[9].size(), 'Last chunk should have 100 records');
    }
    
    @IsTest
    static void testSplitWithVeryLargeDataset() {
        // Arrange
        List<Account> accounts = createTestAccounts(10000);
        DmlChunker chunker = new DmlChunker(500);
        
        // Act
        List<List<SObject>> chunks = chunker.split(accounts);
        
        // Assert
        System.assertEquals(20, chunks.size(), 'Should create 20 chunks for 10000 records with chunk size 500');
        assertChunkSizes(chunks, 500, 'All chunks should have 500 records except the last');
        System.assertEquals(500, chunks[19].size(), 'Last chunk should have 500 records');
    }
    
    // ===== EDGE CASE TESTS =====
    
    @IsTest
    static void testSplitWithChunkSizeOne() {
        // Arrange
        List<Account> accounts = createTestAccounts(5);
        DmlChunker chunker = new DmlChunker(1);
        
        // Act
        List<List<SObject>> chunks = chunker.split(accounts);
        
        // Assert
        System.assertEquals(5, chunks.size(), 'Should create 5 chunks for 5 records with chunk size 1');
        for (Integer i = 0; i < chunks.size(); i++) {
            System.assertEquals(1, chunks[i].size(), 'Each chunk should have 1 record');
        }
    }
    
    @IsTest
    static void testSplitWithChunkSizeLargerThanRecords() {
        // Arrange
        List<Account> accounts = createTestAccounts(10);
        DmlChunker chunker = new DmlChunker(1000);
        
        // Act
        List<List<SObject>> chunks = chunker.split(accounts);
        
        // Assert
        System.assertEquals(1, chunks.size(), 'Should create 1 chunk when chunk size is larger than record count');
        System.assertEquals(10, chunks[0].size(), 'Chunk should contain all records');
    }
    
    @IsTest
    static void testSplitWithBoundaryConditions() {
        // Arrange
        List<Account> accounts = createTestAccounts(99);
        DmlChunker chunker = new DmlChunker(100);
        
        // Act
        List<List<SObject>> chunks = chunker.split(accounts);
        
        // Assert
        System.assertEquals(1, chunks.size(), 'Should create 1 chunk when records are just under chunk size');
        System.assertEquals(99, chunks[0].size(), 'Chunk should contain all records');
    }
    
    @IsTest
    static void testSplitWithBoundaryConditionsExact() {
        // Arrange
        List<Account> accounts = createTestAccounts(100);
        DmlChunker chunker = new DmlChunker(100);
        
        // Act
        List<List<SObject>> chunks = chunker.split(accounts);
        
        // Assert
        System.assertEquals(1, chunks.size(), 'Should create 1 chunk when records exactly match chunk size');
        System.assertEquals(100, chunks[0].size(), 'Chunk should contain all records');
    }
    
    @IsTest
    static void testSplitWithBoundaryConditionsOver() {
        // Arrange
        List<Account> accounts = createTestAccounts(101);
        DmlChunker chunker = new DmlChunker(100);
        
        // Act
        List<List<SObject>> chunks = chunker.split(accounts);
        
        // Assert
        System.assertEquals(2, chunks.size(), 'Should create 2 chunks when records exceed chunk size by 1');
        System.assertEquals(100, chunks[0].size(), 'First chunk should have 100 records');
        System.assertEquals(1, chunks[1].size(), 'Second chunk should have 1 record');
    }
    
    // ===== HETEROGENEOUS RECORD TESTS =====
    
    /**
     * Tests grouping records by SObject type
     */
    @IsTest
    static void testGroupRecordsByType() {
        // Arrange: Create mixed record types
        List<SObject> mixedRecords = new List<SObject>();
        
        List<Account> accounts = new List<Account>();
        accounts.add(new Account(Name = 'Test Account 1'));
        accounts.add(new Account(Name = 'Test Account 2'));
        mixedRecords.addAll(accounts);
        
        List<Contact> contacts = new List<Contact>();
        contacts.add(new Contact(FirstName = 'John', LastName = 'Doe'));
        contacts.add(new Contact(FirstName = 'Jane', LastName = 'Smith'));
        contacts.add(new Contact(FirstName = 'Bob', LastName = 'Johnson'));
        mixedRecords.addAll(contacts);
        
        DmlChunker chunker = new DmlChunker();
        
        // Act: Group records by type
        Test.startTest();
        Map<Schema.SObjectType, List<SObject>> groupedRecords = chunker.groupRecordsByType(mixedRecords);
        Test.stopTest();
        
        // Assert: Records should be grouped correctly
        System.assertEquals(2, groupedRecords.size(), 'Should have 2 different SObject types');
        
        Schema.SObjectType accountType = Account.SObjectType;
        Schema.SObjectType contactType = Contact.SObjectType;
        
        System.assert(groupedRecords.containsKey(accountType), 'Should contain Account type');
        System.assert(groupedRecords.containsKey(contactType), 'Should contain Contact type');
        
        System.assertEquals(2, groupedRecords.get(accountType).size(), 'Should have 2 accounts');
        System.assertEquals(3, groupedRecords.get(contactType).size(), 'Should have 3 contacts');
    }
    
    /**
     * Tests grouping with empty list
     */
    @IsTest
    static void testGroupRecordsByTypeEmpty() {
        DmlChunker chunker = new DmlChunker();
        
        // Act: Group empty list
        Test.startTest();
        Map<Schema.SObjectType, List<SObject>> groupedRecords = chunker.groupRecordsByType(new List<SObject>());
        Test.stopTest();
        
        // Assert: Should return empty map
        System.assertEquals(0, groupedRecords.size(), 'Should return empty map for empty list');
    }
    
    /**
     * Tests grouping with null list
     */
    @IsTest
    static void testGroupRecordsByTypeNull() {
        DmlChunker chunker = new DmlChunker();
        
        // Act: Group null list
        Test.startTest();
        Map<Schema.SObjectType, List<SObject>> groupedRecords = chunker.groupRecordsByType(null);
        Test.stopTest();
        
        // Assert: Should return empty map
        System.assertEquals(0, groupedRecords.size(), 'Should return empty map for null list');
    }
    
    /**
     * Tests grouping with null records in list
     */
    @IsTest
    static void testGroupRecordsByTypeWithNullRecords() {
        List<SObject> mixedRecords = new List<SObject>();
        mixedRecords.add(new Account(Name = 'Test Account'));
        mixedRecords.add(null);
        
        DmlChunker chunker = new DmlChunker();
        
        // Act & Assert: Should throw exception for null records
        Test.startTest();
        try {
            chunker.groupRecordsByType(mixedRecords);
            System.assert(false, 'Should throw exception for null records');
        } catch (IllegalArgumentException ex) {
            System.assert(ex.getMessage().contains('null elements'), 'Should throw appropriate error for null records');
        }
        Test.stopTest();
    }
    
    /**
     * Tests splitting heterogeneous records into chunks
     */
    @IsTest
    static void testSplitHeterogeneous() {
        // Arrange: Create grouped records
        Map<Schema.SObjectType, List<SObject>> groupedRecords = new Map<Schema.SObjectType, List<SObject>>();
        
        // Add 150 accounts (will be split into 2 chunks with default size 100)
        List<SObject> accounts = new List<SObject>();
        for (Integer i = 0; i < 150; i++) {
            accounts.add(new Account(Name = 'Account ' + i));
        }
        groupedRecords.put(Account.SObjectType, accounts);
        
        // Add 50 contacts (will be 1 chunk)
        List<SObject> contacts = new List<SObject>();
        for (Integer i = 0; i < 50; i++) {
            contacts.add(new Contact(FirstName = 'First' + i, LastName = 'Last' + i));
        }
        groupedRecords.put(Contact.SObjectType, contacts);
        
        DmlChunker chunker = new DmlChunker();
        
        // Act: Split heterogeneous records
        Test.startTest();
        Map<Schema.SObjectType, List<List<SObject>>> chunkedRecords = chunker.splitHeterogeneous(groupedRecords);
        Test.stopTest();
        
        // Assert: Should be chunked correctly by type
        System.assertEquals(2, chunkedRecords.size(), 'Should have chunks for 2 types');
        
        List<List<SObject>> accountChunks = chunkedRecords.get(Account.SObjectType);
        List<List<SObject>> contactChunks = chunkedRecords.get(Contact.SObjectType);
        
        System.assertEquals(2, accountChunks.size(), 'Should have 2 account chunks');
        System.assertEquals(100, accountChunks[0].size(), 'First account chunk should have 100 records');
        System.assertEquals(50, accountChunks[1].size(), 'Second account chunk should have 50 records');
        
        System.assertEquals(1, contactChunks.size(), 'Should have 1 contact chunk');
        System.assertEquals(50, contactChunks[0].size(), 'Contact chunk should have 50 records');
    }
    
    /**
     * Tests splitting heterogeneous records with custom chunk size
     */
    @IsTest
    static void testSplitHeterogeneousCustomChunkSize() {
        // Arrange: Create grouped records
        Map<Schema.SObjectType, List<SObject>> groupedRecords = new Map<Schema.SObjectType, List<SObject>>();
        
        List<SObject> accounts = new List<SObject>();
        for (Integer i = 0; i < 25; i++) {
            accounts.add(new Account(Name = 'Account ' + i));
        }
        groupedRecords.put(Account.SObjectType, accounts);
        
        DmlChunker chunker = new DmlChunker(10); // Custom chunk size
        
        // Act: Split heterogeneous records
        Test.startTest();
        Map<Schema.SObjectType, List<List<SObject>>> chunkedRecords = chunker.splitHeterogeneous(groupedRecords);
        Test.stopTest();
        
        // Assert: Should respect custom chunk size
        List<List<SObject>> accountChunks = chunkedRecords.get(Account.SObjectType);
        System.assertEquals(3, accountChunks.size(), 'Should have 3 chunks with size 10');
        System.assertEquals(10, accountChunks[0].size(), 'First chunk should have 10 records');
        System.assertEquals(10, accountChunks[1].size(), 'Second chunk should have 10 records');
        System.assertEquals(5, accountChunks[2].size(), 'Third chunk should have 5 records');
    }
    
    /**
     * Tests splitting heterogeneous with empty map
     */
    @IsTest
    static void testSplitHeterogeneousEmpty() {
        DmlChunker chunker = new DmlChunker();
        
        // Act: Split empty map
        Test.startTest();
        Map<Schema.SObjectType, List<List<SObject>>> chunkedRecords = chunker.splitHeterogeneous(new Map<Schema.SObjectType, List<SObject>>());
        Test.stopTest();
        
        // Assert: Should return empty map
        System.assertEquals(0, chunkedRecords.size(), 'Should return empty map for empty input');
    }
    
    /**
     * Tests splitting heterogeneous with null map
     */
    @IsTest
    static void testSplitHeterogeneousNull() {
        DmlChunker chunker = new DmlChunker();
        
        // Act: Split null map
        Test.startTest();
        Map<Schema.SObjectType, List<List<SObject>>> chunkedRecords = chunker.splitHeterogeneous(null);
        Test.stopTest();
        
        // Assert: Should return empty map
        System.assertEquals(0, chunkedRecords.size(), 'Should return empty map for null input');
    }
}