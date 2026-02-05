/**
 * @description Generates sample data for Medical Insights Intelligence
 * Creates Subjects, Products, Accounts, and sample MedicalInsights
 *
 * Usage: MI_SampleDataGenerator.generateAll();
 */
public with sharing class MI_SampleDataGenerator {

    public class GenerationResult {
        public Integer subjectsCreated = 0;
        public Integer productsCreated = 0;
        public Integer accountsCreated = 0;
        public Integer insightsCreated = 0;
        public List<String> errors = new List<String>();

        public Boolean hasErrors() {
            return !errors.isEmpty();
        }
    }

    /**
     * @description Generates all sample data
     * @return GenerationResult with counts of created records
     */
    public static GenerationResult generateAll() {
        GenerationResult result = new GenerationResult();

        try {
            // Generate Subjects
            List<Subject> subjects = generateSubjects();
            insert subjects;
            result.subjectsCreated = subjects.size();

            // Generate Products
            List<Product2> products = generateProducts();
            insert products;
            result.productsCreated = products.size();

            // Generate Accounts (HCPs)
            List<Account> accounts = generateAccounts();
            insert accounts;
            result.accountsCreated = accounts.size();

            // Generate Sample Insights (optional)
            List<MedicalInsight> insights = generateSampleInsights(subjects, products, accounts);
            insert insights;
            result.insightsCreated = insights.size();

        } catch (Exception e) {
            result.errors.add('Error: ' + e.getMessage());
        }

        return result;
    }

    /**
     * @description Generates standard Subject taxonomy for pharma/life sciences
     */
    public static List<Subject> generateSubjects() {
        List<Subject> subjects = new List<Subject>();

        // Clinical Subjects
        subjects.add(new Subject(
            Name = 'Clinical – Efficacy & Outcomes',
            Description = 'Clinical trial results, real-world efficacy, patient outcomes, response rates',
            UsageType = 'MedicalInsight'
        ));

        subjects.add(new Subject(
            Name = 'Clinical – Safety & Tolerability',
            Description = 'Adverse events, drug interactions, contraindications, safety profiles',
            UsageType = 'MedicalInsight'
        ));

        subjects.add(new Subject(
            Name = 'Clinical – Dosing & Administration',
            Description = 'Titration protocols, dose adjustments, administration routes, timing',
            UsageType = 'MedicalInsight'
        ));

        subjects.add(new Subject(
            Name = 'Clinical – Special Populations',
            Description = 'Pediatrics, geriatrics, pregnancy, renal/hepatic impairment',
            UsageType = 'MedicalInsight'
        ));

        // Market Access Subjects
        subjects.add(new Subject(
            Name = 'Market Access – Prior Authorization',
            Description = 'PA requirements, step therapy, appeals process, approval rates',
            UsageType = 'MedicalInsight'
        ));

        subjects.add(new Subject(
            Name = 'Market Access – Formulary Status',
            Description = 'Formulary placement, tier status, coverage policies, restrictions',
            UsageType = 'MedicalInsight'
        ));

        subjects.add(new Subject(
            Name = 'Market Access – Patient Assistance',
            Description = 'Copay cards, patient support programs, financial assistance, free drug programs',
            UsageType = 'MedicalInsight'
        ));

        // Clinical Practice Subjects
        subjects.add(new Subject(
            Name = 'Practice Patterns – Treatment Sequencing',
            Description = 'Line of therapy, switching patterns, combination use, treatment algorithms',
            UsageType = 'MedicalInsight'
        ));

        subjects.add(new Subject(
            Name = 'Practice Patterns – Patient Selection',
            Description = 'Diagnostic criteria, patient identification, screening protocols',
            UsageType = 'MedicalInsight'
        ));

        subjects.add(new Subject(
            Name = 'Practice Patterns – Monitoring',
            Description = 'Lab monitoring, imaging requirements, follow-up schedules',
            UsageType = 'MedicalInsight'
        ));

        // Competitive Intelligence
        subjects.add(new Subject(
            Name = 'Competitive – Landscape',
            Description = 'Competitor positioning, market share, prescribing trends',
            UsageType = 'MedicalInsight'
        ));

        subjects.add(new Subject(
            Name = 'Competitive – Product Comparison',
            Description = 'Head-to-head data, comparative effectiveness, differentiation',
            UsageType = 'MedicalInsight'
        ));

        // Medical Education
        subjects.add(new Subject(
            Name = 'Education – Knowledge Gaps',
            Description = 'Unmet educational needs, misconceptions, training requirements',
            UsageType = 'MedicalInsight'
        ));

        subjects.add(new Subject(
            Name = 'Education – Guidelines & Literature',
            Description = 'Treatment guidelines, new publications, clinical data updates',
            UsageType = 'MedicalInsight'
        ));

        return subjects;
    }

    /**
     * @description Generates sample pharmaceutical products
     */
    public static List<Product2> generateProducts() {
        List<Product2> products = new List<Product2>();

        products.add(new Product2(
            Name = 'Immunexis 50mg',
            Description = 'Immunotherapy for chronic inflammatory conditions',
            IsActive = true,
            ProductCode = 'IMX-050'
        ));

        products.add(new Product2(
            Name = 'Immunexis 100mg',
            Description = 'Immunotherapy for chronic inflammatory conditions - High dose',
            IsActive = true,
            ProductCode = 'IMX-100'
        ));

        products.add(new Product2(
            Name = 'Cardixol 10mg',
            Description = 'Cardiovascular therapy for heart failure',
            IsActive = true,
            ProductCode = 'CDX-010'
        ));

        products.add(new Product2(
            Name = 'Cardixol 20mg',
            Description = 'Cardiovascular therapy for heart failure - Standard dose',
            IsActive = true,
            ProductCode = 'CDX-020'
        ));

        products.add(new Product2(
            Name = 'NeuroVance 5mg',
            Description = 'Neurological therapy for cognitive decline',
            IsActive = true,
            ProductCode = 'NRV-005'
        ));

        return products;
    }

    /**
     * @description Generates sample HCP accounts
     */
    public static List<Account> generateAccounts() {
        List<Account> accounts = new List<Account>();

        accounts.add(new Account(
            Name = 'Dr. Sarah Chen',
            Description = 'Key Opinion Leader - Rheumatology, Academic Medical Center'
        ));

        accounts.add(new Account(
            Name = 'Dr. Michael Rodriguez',
            Description = 'Community Rheumatologist, High prescriber'
        ));

        accounts.add(new Account(
            Name = 'Dr. Emily Washington',
            Description = 'Cardiologist - Heart Failure Specialist'
        ));

        accounts.add(new Account(
            Name = 'Dr. James Kumar',
            Description = 'Neurologist - Cognitive disorders focus'
        ));

        accounts.add(new Account(
            Name = 'Dr. Lisa Martinez',
            Description = 'Internist with large immunology practice'
        ));

        return accounts;
    }

    /**
     * @description Generates sample MedicalInsights with realistic content
     */
    public static List<MedicalInsight> generateSampleInsights(
        List<Subject> subjects,
        List<Product2> products,
        List<Account> accounts
    ) {
        List<MedicalInsight> insights = new List<MedicalInsight>();

        insights.add(new MedicalInsight(
            Name = 'Immunexis dosing in CKD patients showing variable response',
            Content = 'Dr. Chen reported that her CKD Stage 3 patients on Immunexis 50mg are showing ' +
                     'inconsistent efficacy. She is titrating up to 100mg in some patients with improved ' +
                     'outcomes but increased monitoring burden. Suggests need for CKD-specific dosing guidance.',
            SourceType = 'Account',
            AI_Action_Score__c = 0.85,
            AI_Cluster_Key__c = 'immunexis-ckd-dosing',
            AI_Confidence__c = 0.92
        ));

        insights.add(new MedicalInsight(
            Name = 'Prior authorization delays impacting Cardixol starts',
            Content = 'Dr. Washington mentioned 2-3 week PA delays for Cardixol are causing patients to ' +
                     'start on alternative therapies. She has had 3 patients switch to competitor drugs ' +
                     'while waiting for approval. Requesting streamlined PA process or starter samples.',
            SourceType = 'Account',
            AI_Action_Score__c = 0.95,
            AI_Cluster_Key__c = 'cardixol-pa-delays',
            AI_Confidence__c = 0.88
        ));

        insights.add(new MedicalInsight(
            Name = 'New guideline update favoring earlier Immunexis use',
            Content = 'Dr. Rodriguez shared that updated ACR guidelines now recommend earlier immunotherapy ' +
                     'initiation in moderate disease. This may expand Immunexis patient population. ' +
                     'He is already adjusting his treatment algorithm accordingly.',
            SourceType = 'Account',
            AI_Action_Score__c = 0.78,
            AI_Cluster_Key__c = 'immunexis-guideline-update',
            AI_Confidence__c = 0.95
        ));

        return insights;
    }

    /**
     * @description Deletes all sample data (use with caution!)
     */
    public static void deleteAllSampleData() {
        // Delete in reverse order due to dependencies
        delete [SELECT Id FROM MedicalInsight WHERE Name LIKE '%sample%' OR Name LIKE '%Immunexis%'];
        delete [SELECT Id FROM Account WHERE Name LIKE 'Dr. %'];
        delete [SELECT Id FROM Product2 WHERE ProductCode LIKE 'IMX-%' OR ProductCode LIKE 'CDX-%' OR ProductCode LIKE 'NRV-%'];
        delete [SELECT Id FROM Subject WHERE Description LIKE '%sample%' OR UsageType = 'MedicalInsight'];
    }
}
