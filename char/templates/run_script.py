template = """\
{run_shell}
{PBS_general_settings}{PBS_walltime}{PBS_stagein_settings}{PBS_stageout_settings}

### Display the job context
echo 
echo "Running on host" `hostname`
echo "Time is" `date`
echo "Directory is" `pwd`
{transport_job_context}
{PBS_job_context}

{run_commands}"""
