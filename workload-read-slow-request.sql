\set acc_number random(0, 10000)
SELECT count(*), sum(abalance)
FROM pgbench_accounts
WHERE account_number = :acc_number;
