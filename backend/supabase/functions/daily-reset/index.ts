// Daily Reset Edge Function
// Runs daily at midnight to reset earned time and prepare for new day

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface EarnedTimeRecord {
  child_id: string;
  family_id: string;
  date: string;
  educational_minutes: number;
  required_educational_minutes: number;
  recreational_minutes_used: number;
  recreational_minutes_available: number;
  requirement_met: boolean;
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    const today = new Date().toISOString().split('T')[0]

    console.log(`Running daily reset for date: ${today}`)

    // Get all active children with their families
    const { data: children, error: childrenError } = await supabase
      .from('family_members')
      .select(`
        user_id,
        family_id,
        families!inner(id),
        user_profiles!inner(id, role)
      `)
      .eq('role', 'child')

    if (childrenError) {
      throw childrenError
    }

    console.log(`Found ${children?.length || 0} children to process`)

    // Get active rules
    const { data: rules, error: rulesError } = await supabase
      .from('screen_time_rules')
      .select('*')
      .eq('is_active', true)

    if (rulesError) {
      throw rulesError
    }

    console.log(`Found ${rules?.length || 0} active rules`)

    // Create earned_time records for today for each child
    const earnedTimeRecords: EarnedTimeRecord[] = []

    for (const child of children || []) {
      // Find applicable rule (child-specific or family-wide)
      const applicableRule = rules?.find(
        r => r.child_id === child.user_id || (r.child_id === null && r.family_id === child.family_id)
      )

      if (applicableRule) {
        // Check if today's record already exists
        const { data: existingRecord } = await supabase
          .from('earned_time')
          .select('id')
          .eq('child_id', child.user_id)
          .eq('date', today)
          .single()

        if (!existingRecord) {
          earnedTimeRecords.push({
            child_id: child.user_id,
            family_id: child.family_id,
            date: today,
            educational_minutes: 0,
            required_educational_minutes: applicableRule.required_educational_minutes,
            recreational_minutes_used: 0,
            recreational_minutes_available: 0,
            requirement_met: false,
          })
        }
      }
    }

    // Insert new records
    if (earnedTimeRecords.length > 0) {
      const { error: insertError } = await supabase
        .from('earned_time')
        .insert(earnedTimeRecords)

      if (insertError) {
        throw insertError
      }

      console.log(`Created ${earnedTimeRecords.length} earned_time records for ${today}`)
    }

    // Clean up old usage sessions (older than 90 days)
    const ninetyDaysAgo = new Date()
    ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90)
    const cleanupDate = ninetyDaysAgo.toISOString().split('T')[0]

    const { error: cleanupError } = await supabase
      .from('usage_sessions')
      .delete()
      .lt('date', cleanupDate)

    if (cleanupError) {
      console.error('Error cleaning up old sessions:', cleanupError)
    } else {
      console.log(`Cleaned up usage sessions older than ${cleanupDate}`)
    }

    // Clean up expired parent commands
    const { error: commandCleanupError } = await supabase
      .from('parent_commands')
      .delete()
      .lt('expires_at', new Date().toISOString())

    if (commandCleanupError) {
      console.error('Error cleaning up expired commands:', commandCleanupError)
    } else {
      console.log('Cleaned up expired parent commands')
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Daily reset completed successfully',
        recordsCreated: earnedTimeRecords.length,
        date: today
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )

  } catch (error) {
    console.error('Error in daily reset:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      },
    )
  }
})
