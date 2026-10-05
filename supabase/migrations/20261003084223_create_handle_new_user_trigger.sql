-- Migration to create the missing trigger on auth.users for new profile creation

-- First, drop the trigger if it already exists to ensure idempotency
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create the trigger to execute public.handle_new_user() when a new user is inserted
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();