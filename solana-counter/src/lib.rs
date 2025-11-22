use borsh::{BorshDeserialize, BorshSerialize};
use solana_program::{
    account_info::{next_account_info, AccountInfo},
    entrypoint,
    entrypoint::ProgramResult,
    msg,
    program_error::ProgramError,
    pubkey::Pubkey,
};

/// Define the state stored in accounts
#[derive(BorshSerialize, BorshDeserialize, Debug)]
pub struct CounterAccount {
    pub count: u32,
}

/// Define instruction data
#[derive(BorshSerialize, BorshDeserialize, Debug)]
pub enum CounterInstruction {
    /// Initialize a counter account
    /// Accounts expected:
    /// 0. `[writable]` Counter account to initialize
    Initialize,
    
    /// Increment the counter
    /// Accounts expected:
    /// 0. `[writable]` Counter account to increment
    Increment,
    
    /// Decrement the counter
    /// Accounts expected:
    /// 0. `[writable]` Counter account to decrement
    Decrement,
    
    /// Reset counter to zero
    /// Accounts expected:
    /// 0. `[writable]` Counter account to reset
    Reset,
}

// Declare the program entrypoint
entrypoint!(process_instruction);

// Program entrypoint implementation
pub fn process_instruction(
    program_id: &Pubkey,
    accounts: &[AccountInfo],
    instruction_data: &[u8],
) -> ProgramResult {
    msg!("Counter program entrypoint");

    // Parse instruction
    let instruction = CounterInstruction::try_from_slice(instruction_data)
        .map_err(|_| ProgramError::InvalidInstructionData)?;

    // Get accounts
    let accounts_iter = &mut accounts.iter();
    let account = next_account_info(accounts_iter)?;

    // Check that the account is owned by this program
    if account.owner != program_id {
        msg!("Counter account does not have the correct program id");
        return Err(ProgramError::IncorrectProgramId);
    }

    // Process instruction
    match instruction {
        CounterInstruction::Initialize => {
            msg!("Instruction: Initialize");
            let mut counter = CounterAccount::try_from_slice(&account.data.borrow())?;
            counter.count = 0;
            counter.serialize(&mut &mut account.data.borrow_mut()[..])?;
            msg!("Counter initialized to 0");
        }
        CounterInstruction::Increment => {
            msg!("Instruction: Increment");
            let mut counter = CounterAccount::try_from_slice(&account.data.borrow())?;
            counter.count = counter.count.checked_add(1).unwrap();
            counter.serialize(&mut &mut account.data.borrow_mut()[..])?;
            msg!("Counter incremented to {}", counter.count);
        }
        CounterInstruction::Decrement => {
            msg!("Instruction: Decrement");
            let mut counter = CounterAccount::try_from_slice(&account.data.borrow())?;
            counter.count = counter.count.checked_sub(1).unwrap();
            counter.serialize(&mut &mut account.data.borrow_mut()[..])?;
            msg!("Counter decremented to {}", counter.count);
        }
        CounterInstruction::Reset => {
            msg!("Instruction: Reset");
            let mut counter = CounterAccount::try_from_slice(&account.data.borrow())?;
            counter.count = 0;
            counter.serialize(&mut &mut account.data.borrow_mut()[..])?;
            msg!("Counter reset to 0");
        }
    }

    Ok(())
}