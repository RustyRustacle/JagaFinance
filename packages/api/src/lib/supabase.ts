import { createClient } from "@supabase/supabase-js";
import ws from "ws";

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey || !supabaseAnonKey) {
  throw new Error(
    "SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY and SUPABASE_ANON_KEY must be set in environment"
  );
}

export const supabase = createClient(supabaseUrl, supabaseKey, {
  realtime: {
    transport: ws,
  },
});

export const supabaseAnon = createClient(supabaseUrl, supabaseAnonKey, {
  realtime: {
    transport: ws,
  },
});
