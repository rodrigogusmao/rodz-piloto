-- Tabela de progressão do piloto (XP / nível / estatísticas)
-- Criada automaticamente no boot do recurso, mas disponível aqui para importação manual.
CREATE TABLE IF NOT EXISTS `rodz_piloto_players` (
    `citizenid`        VARCHAR(50) NOT NULL,
    `xp`               INT NOT NULL DEFAULT 0,
    `level`            INT NOT NULL DEFAULT 1,
    `total_deliveries` INT NOT NULL DEFAULT 0,
    `total_earned`     BIGINT NOT NULL DEFAULT 0,
    `history`          LONGTEXT,
    `created_at`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
