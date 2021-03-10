package main

import (
	"encoding/json"
	"fmt"
	"os"

	"github.com/containernetworking/cni/pkg/skel"
	"github.com/containernetworking/cni/pkg/types"
	types100 "github.com/containernetworking/cni/pkg/types/100"
	"github.com/containernetworking/cni/pkg/version"
)

func doCommand(command string, args *skel.CmdArgs) error {
	var conf *types.NetConf = &types.NetConf{}
	//conf := &types.NetConf{}
	if err := json.Unmarshal(args.StdinData, conf); err != nil {
		return fmt.Errorf("failed to unmarshal NetConf from stdin: %v %q", err, string(args.StdinData))
	}

	if err := version.ParsePrevResult(conf); err != nil {
		return err
	}

	if err := log(command, args, conf); err != nil {
		return err
	}

	result := conf.PrevResult
	if result == nil {
		result = &types100.Result{
			CNIVersion: types100.ImplementedSpecVersion,
		}
	}
	return types.PrintResult(result, conf.CNIVersion)
}

type logRecord struct {
	Command string
	Args    *skel.CmdArgs
	NetConf *types.NetConf
}

func log(command string, args *skel.CmdArgs, conf *types.NetConf) error {
	file, err := os.OpenFile("/tmp/cni-noop.log", os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0600)
	if err != nil {
		return err
	}

	defer file.Close()

	bytes, err := json.Marshal(logRecord{
		Command: command,
		Args:    args,
		NetConf: conf})
	if err != nil {
		return err
	}

	_, err = file.Write(bytes)
	if err != nil {
		return err
	}

	_, err = file.WriteString("\n")
	if err != nil {
		return err
	}
	return nil
}

func cmdAdd(args *skel.CmdArgs) error {
	return doCommand("ADD", args)
}

func cmdCheck(args *skel.CmdArgs) error {
	return doCommand("CHECK", args)
}

func cmdDel(args *skel.CmdArgs) error {
	return doCommand("DEL", args)
}

func main() {
	skel.PluginMain(cmdAdd, cmdCheck, cmdDel, version.All, "noop CNI plugin")
}
