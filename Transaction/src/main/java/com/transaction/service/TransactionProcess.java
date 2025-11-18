package com.transaction.service;

import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.bind.annotation.RequestHeader;

import com.transaction.model.DTO.AccountPayload;
import com.transaction.model.DTO.TransactionDTO;
import com.transaction.model.TransacType;
import com.transaction.model.Transaction;
import com.transaction.repository.TransactionRepository;

import lombok.RequiredArgsConstructor;
import reactor.core.publisher.Mono;

@Service
@RequiredArgsConstructor
public class TransactionProcess {
    private final TransactionService transactionService;
    private final TransactionRepository transactionRepository;
    private static final Logger log = LoggerFactory.getLogger(TransactionProcess.class);

    // Reactive helper method to validate an account
    private Mono<Boolean> isInvalidAccount(UUID accountNumber, String jwtToken) {
        return transactionService.isAccountValid(accountNumber, jwtToken)
                .map(valid -> !valid);
    }

    // Reactive transaction process
    public Mono<Transaction> transactionProcess(TransactionDTO transactionDTO, @RequestHeader("Authorization") String authorizationHeader) {
        String jwtToken = authorizationHeader.replace("Bearer ", "");
        return Mono.zip(
                isInvalidAccount(transactionDTO.getAccNoOwner(), jwtToken),
                isInvalidAccount(transactionDTO.getAccNoReceive(), jwtToken)
        ).flatMap(validTuple -> {
            if (validTuple.getT1() || validTuple.getT2()) {
                return Mono.error(new IllegalArgumentException("Invalid account details"));
            }
            return Mono.zip(
                    transactionService.getAccountDetail(transactionDTO.getAccNoOwner(), jwtToken),
                    transactionService.getAccountDetail(transactionDTO.getAccNoReceive(), jwtToken)
            );
        }).flatMap(payloadTuple -> {
            AccountPayload ownerPayload = payloadTuple.getT1();
            AccountPayload receiverPayload = payloadTuple.getT2();

            log.info("Owner Payload: {}", ownerPayload);
            log.info("Receiver Payload: {}", receiverPayload);

            if (ownerPayload.getBalance().compareTo(transactionDTO.getAmount()) < 0) {
                return Mono.error(new IllegalArgumentException("Insufficient funds"));
            }
            if(!ownerPayload.getCurrency().equals(receiverPayload.getCurrency())) {
                return Mono.error(new IllegalArgumentException("Currency mismatch between accounts"));
            }

            ownerPayload.setBalance(ownerPayload.getBalance().subtract(transactionDTO.getAmount()));
            receiverPayload.setBalance(receiverPayload.getBalance().add(transactionDTO.getAmount()));

            Transaction transaction = new Transaction(
                    transactionDTO.getAccNoOwner(),
                    transactionDTO.getAccNoReceive(),
                    transactionDTO.getAmount(),
                    TransacType.Transaction.name()
            );
            log.info("Processing transaction from Owner {} to Receiver {}", transactionDTO.getAccNoOwner(), transactionDTO.getAccNoReceive());

            return transactionRepository.save(transaction)
                .flatMap(savedTx -> 
                    Mono.when(
                        transactionService.updateAccountBalance("account-balance-update", ownerPayload, jwtToken),
                        transactionService.updateAccountBalance("account-balance-update", receiverPayload, jwtToken)
                    ).thenReturn(savedTx)
                );
        }).doOnSuccess(tx -> {
            log.info("Transaction processed successfully: Owner {} to Receiver {}", transactionDTO.getAccNoOwner(), transactionDTO.getAccNoReceive());
            log.info("Transaction amount: {}", transactionDTO.getAmount());
        }).doOnError(e -> {
            log.error("Error processing transaction: {}", e.getMessage());
        });
    }

    // Reactive deposit process
    public Mono<Transaction> depositProcess(TransactionDTO transactionDTO, @RequestHeader("Authorization") String authorizationHeader) {
        String jwtToken = authorizationHeader.replace("Bearer ", "");
        return isInvalidAccount(transactionDTO.getAccNoOwner(), jwtToken)
            .flatMap(invalid -> {
                if (invalid) {
                    return Mono.error(new IllegalArgumentException("Invalid account details"));
                }
                return transactionService.getAccountDetail(transactionDTO.getAccNoOwner(), jwtToken);
            })
            .flatMap(ownerPayload -> {
                if (ownerPayload == null) {
                    return Mono.error(new IllegalArgumentException("Invalid account details"));
                }
                ownerPayload.setBalance(ownerPayload.getBalance().add(transactionDTO.getAmount()));
                Transaction transaction = new Transaction(
                        transactionDTO.getAccNoOwner(),
                        transactionDTO.getAmount(),
                        TransacType.Deposit.name()
                );
                return transactionRepository.save(transaction)
                        .flatMap(savedTx ->
                                transactionService.updateAccountBalance("account-balance-update", ownerPayload, jwtToken)
                                        .thenReturn(savedTx)
                        );
            })
            .doOnSuccess(tx -> {
                log.info("Deposit processed successfully for account: {}", transactionDTO.getAccNoOwner());
                log.info("Deposit amount: {}", transactionDTO.getAmount());
            })
            .doOnError(e -> {
                log.error("Error processing deposit transaction: {}", e.getMessage());
            });
    }

    // Reactive withdraw process
    public Mono<Transaction> withdrawProcess(TransactionDTO transactionDTO, @RequestHeader("Authorization") String authorizationHeader) {
        String jwtToken = authorizationHeader.replace("Bearer ", "");
        return isInvalidAccount(transactionDTO.getAccNoOwner(), jwtToken)
            .flatMap(invalid -> {
                if (invalid) {
                    return Mono.error(new IllegalArgumentException("Invalid account details"));
                }
                return transactionService.getAccountDetail(transactionDTO.getAccNoOwner(), jwtToken);
            })
            .flatMap(ownerPayload -> {
                if (ownerPayload == null) {
                    return Mono.error(new IllegalArgumentException("Invalid account details"));
                }
                if (ownerPayload.getBalance().compareTo(transactionDTO.getAmount()) < 0) {
                    return Mono.error(new IllegalArgumentException("Insufficient funds"));
                }
                ownerPayload.setBalance(ownerPayload.getBalance().subtract(transactionDTO.getAmount()));
                Transaction transaction = new Transaction(
                        transactionDTO.getAccNoOwner(),
                        transactionDTO.getAmount(),
                        TransacType.Withdraw.name()
                );
                return transactionRepository.save(transaction)
                        .flatMap(savedTx ->
                                transactionService.updateAccountBalance("account-balance-update", ownerPayload, jwtToken)
                                        .thenReturn(savedTx)
                        );
            })
            .doOnSuccess(tx -> {
                log.info("Withdrawal processed successfully for account: {}", transactionDTO.getAccNoOwner());
                log.info("Withdrawal amount: {}", transactionDTO.getAmount());
            })
            .doOnError(e -> {
                log.error("Error processing withdrawal transaction: {}", e.getMessage());
            });
    }
}
